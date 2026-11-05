//
//  CollectiblesWidgetProvider.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import CombineExt
import TangemFoundation

final class CollectiblesWidgetProvider {
    @Injected(\.userWalletRepository) private var userWalletRepository: UserWalletRepository

    private let walletsSubject = CurrentValueSubject<[UserWalletModel], Never>([])
    private let regionStatusTask: Task<CollectiblesRegionStatus, Never>
    private let router: any CollectiblesFeedRoutable
    private var bag = Set<AnyCancellable>()

    init(
        router: any CollectiblesFeedRoutable,
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

            provider.router.openCollectibles(wallets: wallets, isRegionRestricted: status == .restricted)
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
            .flatMapLatest { provider, _ in provider.enterableWallets() }
            .receiveOnMain()
            .sink { [walletsSubject] wallets in walletsSubject.send(wallets) }
            .store(in: &bag)
    }

    func enterableWallets() -> AnyPublisher<[UserWalletModel], Never> {
        let wallets = userWalletRepository.models.filter(\.isCollectiblesEligible)

        guard wallets.isNotEmpty else {
            return .just(output: [])
        }

        return wallets
            .map(\.collectiblesSyncRequiredPublisher)
            .combineLatest()
            .map { syncRequirements in
                zip(wallets, syncRequirements).filter { !$0.1 }.map(\.0)
            }
            .eraseToAnyPublisher()
    }
}
