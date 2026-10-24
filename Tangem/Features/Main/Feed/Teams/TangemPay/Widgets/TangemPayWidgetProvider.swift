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
        entrySubject
            .map { $0 == nil ? nil : FeedWidget.tangemPay }
            .eraseToAnyPublisher()
    }

    func select() {
        guard let entry = entrySubject.value else { return }

        router.openTangemPay(entry)
    }
}

// MARK: - Private

private extension TangemPayWidgetProvider {
    func bind() {
        Publishers
            .CombineLatest(
                tangemPayAvailabilityRepository.tangemPayFeedCardEntrypointEligibleWalletSelectionPublisher,
                walletsOnboardingEntryPublisher()
            )
            .map { walletSelection, onboardingEntry in
                onboardingEntry ?? walletSelection.map(FeedTangemPayEntry.offer)
            }
            .receiveOnMain()
            .withWeakCaptureOf(self)
            .sink { provider, entry in provider.entrySubject.send(entry) }
            .store(in: &bag)
    }

    func walletsOnboardingEntryPublisher() -> AnyPublisher<FeedTangemPayEntry?, Never> {
        guard !RTCUtil.isRootedDevice else {
            return .just(output: nil)
        }

        return userWalletRepository.eventProvider
            .filter { event in
                switch event {
                case .selected: false
                default: true
                }
            }
            .mapToVoid()
            .prepend(())
            .withWeakCaptureOf(self)
            .flatMapLatest { provider, _ -> AnyPublisher<FeedTangemPayEntry?, Never> in
                let customerPublishers = provider.userWalletRepository.models.map { provider.customerPublisher(for: $0) }

                guard !customerPublishers.isEmpty else {
                    return .just(output: nil)
                }

                return customerPublishers
                    .combineLatest()
                    .map { Customer.onboardingEntry(across: $0.compactMap(\.self)) }
                    .eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
    }

    func customerPublisher(for wallet: UserWalletModel) -> AnyPublisher<Customer?, Never> {
        AccountModelsAggregator(.tangemPay)
            .modelPublisher(from: wallet.accountModelsManager)
            .prepend(AccountModelsAggregator(.tangemPay).model(from: wallet.accountModelsManager))
            .flatMapLatest { model -> AnyPublisher<Customer?, Never> in
                guard let model else {
                    return .just(output: nil)
                }

                return model.statePublisher
                    .mapToVoid()
                    .prepend(())
                    .map { FeedTangemPayEntry.resolve(customer: model, wallet: wallet).map(Customer.onboarding) ?? .enrolled }
                    .eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
    }
}

// MARK: - Customer

private extension TangemPayWidgetProvider {
    enum Customer {
        case onboarding(FeedTangemPayEntry)
        case enrolled

        static func onboardingEntry(across customers: [Customer]) -> FeedTangemPayEntry? {
            var onboardingEntry: FeedTangemPayEntry?

            for customer in customers {
                switch customer {
                case .onboarding(let entry):
                    onboardingEntry = onboardingEntry ?? entry
                case .enrolled:
                    return nil
                }
            }

            return onboardingEntry
        }
    }
}
