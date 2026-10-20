//
//  TokenSelectorItemSwapAvailabilityProvider.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Combine
import TangemFoundation

final class TokenSelectorItemSwapAvailabilityProvider {
    private var direction: CurrentValueSubject<SwapDirection?, Never> = .init(nil)
    private var directionSubscription: AnyCancellable?

    func setup(directionPublisher: some Publisher<SwapDirection?, Never>) {
        directionSubscription = directionPublisher
            .assign(to: \.direction.value, on: self, ownership: .weak)
    }
}

// MARK: - TokenSelectorItemAvailabilityProvider

extension TokenSelectorItemSwapAvailabilityProvider: TokenSelectorItemAvailabilityProvider {
    func availabilityTypePublisher(userWalletInfo: UserWalletInfo, walletModel: any WalletModel) -> AnyPublisher<TokenSelectorItem.AvailabilityType, Never> {
        let availabilityTypePublisher = Publishers
            .CombineLatest(walletModel.actionsUpdatePublisher, direction)
            .withWeakCaptureOf(self)
            .map { provider, values in
                provider.disabledReason(
                    userWalletInfo: userWalletInfo,
                    walletModel: walletModel,
                    direction: values.1
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
        direction: SwapDirection?
    ) -> TokenSelectorItem.AvailabilityType {
        let availabilityProvider = TokenActionAvailabilityProvider(
            userWalletInfo: userWalletInfo,
            walletModel: walletModel
        )

        guard availabilityProvider.isTokenInteractionAvailable() else {
            return .unavailable(reason: .unavailableForSwap(.noAddress))
        }

        switch direction {
        case .fromSource:
            let swapState = availabilityProvider.swapReceiveAvailability()
            guard swapState.isAvailable else {
                return .unavailable(reason: .unavailableForSwap(.receiveState(swapState)))
            }

        case .toDestination, .none:
            let swapState = availabilityProvider.swapSourceAvailability()
            guard case .available = swapState else {
                return .unavailable(reason: .unavailableForSwap(.sourceState(swapState)))
            }
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
