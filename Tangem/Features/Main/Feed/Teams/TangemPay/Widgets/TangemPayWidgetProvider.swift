//
//  TangemPayWidgetProvider.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import CombineExt
import TangemFoundation

final class TangemPayWidgetProvider {
    @Injected(\.userWalletRepository) private var userWalletRepository: UserWalletRepository
    @Injected(\.tangemPayAvailabilityRepository) private var tangemPayAvailabilityRepository: TangemPayAvailabilityRepository

    private let entrySubject = CurrentValueSubject<FeedTangemPayEntry?, Never>(nil)
    private weak var router: FeedWidgetsRoutable?
    private var bag = Set<AnyCancellable>()

    init(router: FeedWidgetsRoutable) {
        self.router = router
        bind()
    }
}

// MARK: - FeedWidgetProvider

extension TangemPayWidgetProvider: FeedWidgetProvider {
    var widgetPublisher: AnyPublisher<FeedWidget?, Never> {
        entrySubject
            .map { $0 == nil ? nil : FeedWidget.tangemPay }
            .eraseToAnyPublisher()
    }

    func select() {
        guard let entry = entrySubject.value else { return }

        router?.openTangemPay(entry)
    }
}

// MARK: - Private

private extension TangemPayWidgetProvider {
    func bind() {
        userWalletRepository.selectedUnlockedModelPublisher
            .withWeakCaptureOf(self)
            .flatMapLatest { provider, wallet -> AnyPublisher<FeedTangemPayEntry?, Never> in
                guard let wallet else {
                    return .just(output: nil)
                }

                return provider.entryPublisher(for: wallet)
            }
            .receiveOnMain()
            .withWeakCaptureOf(self)
            .sink { provider, entry in provider.entrySubject.send(entry) }
            .store(in: &bag)
    }

    func entryPublisher(for wallet: UserWalletModel) -> AnyPublisher<FeedTangemPayEntry?, Never> {
        let offer = tangemPayAvailabilityRepository
            .tangemPayFeedCardEntrypointEligibleWalletSelectionPublisher(for: wallet.userWalletId.stringValue)

        let customer = TangemPayAccountAggregator
            .tangemPayAccountModelPublisher(from: wallet.accountModelsManager)
            .flatMapLatest { model -> AnyPublisher<(any TangemPayAccountModel)?, Never> in
                guard let model else {
                    return .just(output: nil)
                }

                return model.statePublisher
                    .map { _ -> (any TangemPayAccountModel)? in model }
                    .prepend(Optional(model))
                    .eraseToAnyPublisher()
            }

        return Publishers.CombineLatest(offer, customer)
            .map { FeedTangemPayEntry.resolve(offer: $0, customer: $1, wallet: wallet) }
            .eraseToAnyPublisher()
    }
}
