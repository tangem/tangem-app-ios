//
//  AccountsAwareTokenSelectorItemSwapAvailabilityProvider.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Combine
import TangemExpress

final class AccountsAwareTokenSelectorItemSwapAvailabilityProvider {
    @Injected(\.expressPairsRepository)
    private var expressPairsRepository: ExpressPairsRepository

    private var availableCurrencies: CurrentValueSubject<[ExpressCurrency]?, Never> = .init(nil)
    private var directionSubscription: AnyCancellable?

    init() {}

    func setup(directionPublisher: some Publisher<SwapDirection?, Never>) {
        directionSubscription = directionPublisher
            .withWeakCaptureOf(self)
            .asyncMap { provider, direction in
                switch direction {
                case .none:
                    return .none
                case .fromSource(let source):
                    let pairs = await provider.expressPairsRepository.getPairs(from: source.expressCurrency)
                    // We add the `source` token because it pair will not contains it as `destination`
                    // But of course it's available for swap as `source`
                    return [source.expressCurrency.asCurrency] + pairs.map { $0.destination }
                case .toDestination(let destination):
                    let pairs = await provider.expressPairsRepository.getPairs(to: destination.expressCurrency)
                    // We add the `destination` token because it pair will not contains it as `source`
                    // But of course it's available for swap as `destination`
                    return [destination.expressCurrency.asCurrency] + pairs.map { $0.source }
                }
            }
            .assign(to: \.availableCurrencies.value, on: self, ownership: .weak)
    }
}

// MARK: - AccountsAwareTokenSelectorItemAvailabilityProvider

extension AccountsAwareTokenSelectorItemSwapAvailabilityProvider: AccountsAwareTokenSelectorItemAvailabilityProvider {
    func availabilityTypePublisher(userWalletInfo: UserWalletInfo, walletModel: any WalletModel) -> AnyPublisher<AccountsAwareTokenSelectorItem.AvailabilityType, Never> {
        let availabilityTypePublisher = Publishers
            .CombineLatest(walletModel.actionsUpdatePublisher, availableCurrencies)
            .map { $1 }
            .withWeakCaptureOf(self)
            .map { provider, availableCurrencies in
                provider.disabledReason(
                    userWalletInfo: userWalletInfo,
                    walletModel: walletModel,
                    availableCurrencies: availableCurrencies
                )
            }
            .eraseToAnyPublisher()

        return availabilityTypePublisher
    }
}

// MARK: - Private

private extension AccountsAwareTokenSelectorItemSwapAvailabilityProvider {
    func disabledReason(
        userWalletInfo: UserWalletInfo,
        walletModel: any WalletModel,
        availableCurrencies: [ExpressCurrency]?
    ) -> AccountsAwareTokenSelectorItem.AvailabilityType {
        let availabilityProvider = TokenActionAvailabilityProvider(
            userWalletConfig: userWalletInfo.config,
            walletModel: walletModel
        )

        guard case .available = availabilityProvider.swapAvailability else {
            return .unavailable(reason: .unavailableForSwap)
        }

        // If we have direction we have to check available pairs
        if let availableCurrencies {
            let hasPair = availableCurrencies.contains(walletModel.tokenItem.expressCurrency.asCurrency)
            return hasPair ? .available : .unavailable(reason: .unavailableForSwap)
        }

        return .available
    }
}

// MARK: - SwapDirection

extension AccountsAwareTokenSelectorItemSwapAvailabilityProvider {
    enum SwapDirection {
        case fromSource(TokenItem)
        case toDestination(TokenItem)
    }
}
