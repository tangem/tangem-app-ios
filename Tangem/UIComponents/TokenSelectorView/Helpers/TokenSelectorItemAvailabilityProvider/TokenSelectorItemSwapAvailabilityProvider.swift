//
//  TokenSelectorItemSwapAvailabilityProvider.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Combine
import TangemExpress
import TangemFoundation

final class TokenSelectorItemSwapAvailabilityProvider {
    @Injected(\.swapRepository)
    private var swapRepository: SwapRepository

    private var availableCurrencies: CurrentValueSubject<[ExpressCurrency]?, Never> = .init(nil)
    private var directionSubscription: AnyCancellable?

    func setup(directionPublisher: some Publisher<SwapDirection?, Never>) {
        directionSubscription = directionPublisher
            .withWeakCaptureOf(self)
            .asyncMap { provider, direction in
                switch direction {
                case .fromSource(.some(let source)):
                    return await provider.swapRepository.getPairs(from: source.tokenItem.expressCurrency).map(\.destination)

                case .toDestination(.some(let destination)):
                    return await provider.swapRepository.getPairs(to: destination.tokenItem.expressCurrency).map(\.source)

                case .none, .fromSource, .toDestination:
                    return .none
                }
            }
            .assign(to: \.availableCurrencies.value, on: self, ownership: .weak)
    }
}

// MARK: - TokenSelectorItemAvailabilityProvider

extension TokenSelectorItemSwapAvailabilityProvider: TokenSelectorItemAvailabilityProvider {
    func availabilityTypePublisher(userWalletInfo: UserWalletInfo, walletModel: any WalletModel) -> AnyPublisher<TokenSelectorItem.AvailabilityType, Never> {
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

private extension TokenSelectorItemSwapAvailabilityProvider {
    func disabledReason(
        userWalletInfo: UserWalletInfo,
        walletModel: any WalletModel,
        availableCurrencies: [ExpressCurrency]?
    ) -> TokenSelectorItem.AvailabilityType {
        let availabilityProvider = TokenActionAvailabilityProvider(
            userWalletConfig: userWalletInfo.config,
            walletModel: walletModel
        )

        guard availabilityProvider.isTokenInteractionAvailable() else {
            return .unavailable(reason: .unavailableForSwap(.noAddress))
        }

        let swapState = availabilityProvider.swapAvailability
        guard case .available = swapState else {
            return .unavailable(reason: .unavailableForSwap(.swapState(swapState)))
        }

        return .available
    }
}

// MARK: - SwapDirection

extension TokenSelectorItemSwapAvailabilityProvider {
    enum SwapDirection {
        case fromSource(WalletTokenItem?)
        case toDestination(WalletTokenItem?)
    }
}
