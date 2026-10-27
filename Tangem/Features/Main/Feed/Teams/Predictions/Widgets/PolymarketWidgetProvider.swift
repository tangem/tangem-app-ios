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
    private let router: any PredictionsFeedRoutable
    private let presenceStore: PolymarketAccountPresenceStore
    private var bag = Set<AnyCancellable>()

    init(router: any PredictionsFeedRoutable, presenceStore: PolymarketAccountPresenceStore = AppSettings.shared) {
        self.router = router
        self.presenceStore = presenceStore

        bind()
    }
}

// MARK: - FeedWidgetProvider

extension PolymarketWidgetProvider: FeedWidgetProvider {
    var widgetPublisher: AnyPublisher<FeedWidget?, Never> {
        walletsSubject
            .map { [availabilityProvider, presenceStore] wallets -> AnyPublisher<Bool, Never> in
                guard wallets.isNotEmpty else { return .just(output: false) }

                let userWalletIds = wallets.map(\.userWalletId)

                return availabilityProvider.isAvailablePublisher(hasAccount: {
                    userWalletIds.contains(where: presenceStore.hasAccount(userWalletId:))
                })
            }
            .switchToLatest()
            .map { isAvailable in isAvailable ? FeedWidget.polymarket : nil }
            .removeDuplicates()
            .eraseToAnyPublisher()
    }

    func select() {
        router.openPolymarket(wallets: walletsSubject.value)
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
