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

    private let walletSubject = CurrentValueSubject<UserWalletModel?, Never>(nil)
    private let router: any PredictionsFeedRoutable
    private var bag = Set<AnyCancellable>()

    init(router: any PredictionsFeedRoutable) {
        self.router = router

        bind()
    }
}

// MARK: - FeedWidgetProvider

extension PolymarketWidgetProvider: FeedWidgetProvider {
    var widgetPublisher: AnyPublisher<FeedWidget?, Never> {
        walletSubject
            .map { $0 == nil ? nil : FeedWidget.polymarket }
            .removeDuplicates()
            .eraseToAnyPublisher()
    }

    func select() {
        guard let wallet = walletSubject.value else { return }

        router.openPolymarketMain(wallet: wallet)
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
            .sink { provider, _ in provider.resolveWallet() }
            .store(in: &bag)
    }

    func resolveWallet() {
        let selected = userWalletRepository.selectedModel
        let wallet = selected.flatMap { $0.isUserWalletLocked ? nil : $0 }
            ?? userWalletRepository.models.first { !$0.isUserWalletLocked }

        walletSubject.send(wallet)
    }
}
