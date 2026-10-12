//
//  TangemPayWidgetProvider.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import TangemFoundation

final class TangemPayWidgetProvider {
    @Injected(\.tangemPayAvailabilityRepository) private var tangemPayAvailabilityRepository: TangemPayAvailabilityRepository

    private let walletSelectionSubject = CurrentValueSubject<TangemPayWalletSelectionType?, Never>(nil)
    private let router: any TangemPayFeedRoutable
    private var bag = Set<AnyCancellable>()

    init(router: any TangemPayFeedRoutable) {
        self.router = router
        bind()
    }
}

// MARK: - FeedWidgetProvider

extension TangemPayWidgetProvider: FeedWidgetProvider {
    var widgetPublisher: AnyPublisher<FeedWidget?, Never> {
        walletSelectionSubject
            .map { $0 == nil ? nil : FeedWidget.tangemPay }
            .eraseToAnyPublisher()
    }

    func select() {
        guard let walletSelection = walletSelectionSubject.value else { return }

        router.openTangemPay(.offer(walletSelection))
    }
}

// MARK: - Private

private extension TangemPayWidgetProvider {
    func bind() {
        tangemPayAvailabilityRepository.tangemPayFeedCardEntrypointEligibleWalletSelectionPublisher
            .receiveOnMain()
            .withWeakCaptureOf(self)
            .sink { provider, walletSelection in provider.walletSelectionSubject.send(walletSelection) }
            .store(in: &bag)
    }
}
