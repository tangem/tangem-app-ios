//
//  CollectiblesWidgetProvider.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import TangemFoundation

final class CollectiblesWidgetProvider {
    @Injected(\.userWalletRepository) private var userWalletRepository: UserWalletRepository

    private let walletsSubject = CurrentValueSubject<[UserWalletModel], Never>([])
    private let regionStatusTask: Task<CollectiblesRegionStatus, Never>
    private weak var router: FeedWidgetsRoutable?
    private var bag = Set<AnyCancellable>()

    init(
        router: FeedWidgetsRoutable,
        geoblockProvider: some CollectiblesGeoblockProvider = CollectiblesGeoblockMockProvider()
    ) {
        self.router = router

        regionStatusTask = Task {
            do {
                return try await geoblockProvider.load()
            } catch {
                return .allowed
            }
        }

        bind()
    }
}

// MARK: - FeedWidgetProvider

extension CollectiblesWidgetProvider: FeedWidgetProvider {
    var widgetPublisher: AnyPublisher<FeedWidget?, Never> {
        walletsSubject
            .map { $0.isEmpty ? nil : FeedWidget.collectibles }
            .removeDuplicates()
            .eraseToAnyPublisher()
    }

    func select() {
        let wallets = walletsSubject.value

        runTask(in: self) { provider in
            let status = await provider.regionStatusTask.value

            provider.router?.openCollectibles(wallets: wallets, isRegionRestricted: status == .restricted)
        }
    }
}

// MARK: - Private

private extension CollectiblesWidgetProvider {
    func bind() {
        userWalletRepository
            .eventProvider
            .mapToVoid()
            .prepend(())
            .receiveOnMain()
            .withWeakCaptureOf(self)
            .sink { provider, _ in provider.resolveWallets() }
            .store(in: &bag)
    }

    func resolveWallets() {
        walletsSubject.send(userWalletRepository.models.filter(\.isCollectiblesEligible))
    }
}
