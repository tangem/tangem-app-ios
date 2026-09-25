//
//  PolymarketWidgetProvider.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import TangemFoundation

final class PolymarketWidgetProvider {
    @Injected(\.userWalletRepository) private var userWalletRepository: UserWalletRepository
    @Injected(\.polymarketAvailabilityProvider) private var availabilityProvider: PolymarketAvailabilityProvider

    private let walletsSubject = CurrentValueSubject<[UserWalletModel], Never>([])
    private weak var router: FeedWidgetsRoutable?
    private var bag = Set<AnyCancellable>()

    init(router: FeedWidgetsRoutable) {
        self.router = router

        bind()
    }
}

// MARK: - FeedWidgetProvider

extension PolymarketWidgetProvider: FeedWidgetProvider {
    var widgetPublisher: AnyPublisher<FeedWidget?, Never> {
        Publishers
            .CombineLatest(walletsSubject, availabilityProvider.isAvailablePublisher)
            .map { wallets, isAvailable in
                guard isAvailable, wallets.isNotEmpty else { return nil }

                return FeedWidget.polymarket
            }
            .removeDuplicates()
            .eraseToAnyPublisher()
    }

    func select() {
        router?.openPolymarket(wallets: walletsSubject.value)
    }
}

// MARK: - Private

private extension PolymarketWidgetProvider {
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
        walletsSubject.send(userWalletRepository.models.filter(\.supportsPolymarket))
    }
}
