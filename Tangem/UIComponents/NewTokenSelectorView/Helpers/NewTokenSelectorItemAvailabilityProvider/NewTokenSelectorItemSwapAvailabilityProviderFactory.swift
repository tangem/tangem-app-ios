//
//  NewTokenSelectorItemSwapAvailabilityProviderFactory.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Combine
import TangemExpress

final class NewTokenSelectorItemSwapAvailabilityProviderFactory: NewTokenSelectorItemAvailabilityProviderFactory {
    @Injected(\.expressPairsRepository)
    private var expressPairsRepository: ExpressPairsRepository

    private var availableCurrencies: CurrentValueSubject<[ExpressCurrency]?, Never> = .init(nil)
    private var directionSubscription: AnyCancellable?

    init(directionPublisher: AnyPublisher<SwapDirection?, Never>) {
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

    func makeAvailabilityProvider(userWalletInfo: UserWalletInfo, walletModel: any WalletModel) -> any NewTokenSelectorItemAvailabilityProvider {
        let availabilityTypePublisher = Publishers
            .CombineLatest(walletModel.actionsUpdatePublisher, availableCurrencies)
            .map { $1 }
            .withWeakCaptureOf(self)
            .map { factory, availableCurrencies in
                factory.disabledReason(
                    userWalletInfo: userWalletInfo,
                    walletModel: walletModel,
                    availableCurrencies: availableCurrencies
                )
            }
            .eraseToAnyPublisher()

        return NewTokenSelectorItemSwapAvailabilityProvider(
            availabilityTypePublisher: availabilityTypePublisher
        )
    }

    func disabledReason(
        userWalletInfo: UserWalletInfo,
        walletModel: any WalletModel,
        availableCurrencies: [ExpressCurrency]?
    ) -> NewTokenSelectorItem.AvailabilityType {
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

extension NewTokenSelectorItemSwapAvailabilityProviderFactory {
    enum SwapDirection {
        case fromSource(TokenItem)
        case toDestination(TokenItem)
    }
}

// MARK: - NewTokenSelectorItemSwapAvailabilityProvider

struct NewTokenSelectorItemSwapAvailabilityProvider: NewTokenSelectorItemAvailabilityProvider {
    let availabilityTypePublisher: AnyPublisher<NewTokenSelectorItem.AvailabilityType, Never>
}
