//
//  SwapSummaryInteractor.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import Foundation
import TangemFoundation

protocol SwapSummaryInteractor: AnyObject {
    var isUpdatingPublisher: AnyPublisher<Bool, Never> { get }
    var isReadyToSendPublisher: AnyPublisher<Bool, Never> { get }
    var isMaxAmountButtonHiddenPublisher: AnyPublisher<Bool, Never> { get }
    var areAmountFractionsHiddenPublisher: AnyPublisher<Bool, Never> { get }
    var transactionDescription: AnyPublisher<AttributedString?, Never> { get }
    var isNotificationButtonIsLoading: AnyPublisher<Bool, Never> { get }
    var isActionInProcessing: AnyPublisher<Bool, Never> { get }
    var mainButtonStatePublisher: AnyPublisher<SwapSummaryViewModel.MainButtonState, Never> { get }

    func userDidRequestSwapSourceAndReceiveToken()
    // [REDACTED_TODO_COMMENT]
    func userDidRequestMaxAmount()
    func userDidRequestSourceAmount(fraction: SwapAmountFraction)
    func userDidRequestSwap()
}

class CommonSwapSummaryInteractor {
    private weak var input: SwapSummaryInput?
    private weak var output: SwapSummaryOutput?
    private weak var sourceTokenInput: SendSourceTokenInput?
    private weak var swapModelStateProvider: SwapModelStateProvider?

    private let swapDescriptionBuilder: SwapTransactionSummaryDescriptionBuilder

    init(
        input: SwapSummaryInput,
        output: SwapSummaryOutput,
        sourceTokenInput: SendSourceTokenInput,
        receiveTokenAmountInput: SendReceiveTokenAmountInput?,
        swapModelStateProvider: SwapModelStateProvider,
        swapDescriptionBuilder: SwapTransactionSummaryDescriptionBuilder,
    ) {
        self.input = input
        self.output = output
        self.sourceTokenInput = sourceTokenInput
        self.swapModelStateProvider = swapModelStateProvider
        self.swapDescriptionBuilder = swapDescriptionBuilder
    }
}

// MARK: - SwapSummaryInteractor

extension CommonSwapSummaryInteractor: SwapSummaryInteractor {
    var transactionDescription: AnyPublisher<AttributedString?, Never> {
        guard let input else {
            assertionFailure("SendSummaryInput is not found")
            return Empty().eraseToAnyPublisher()
        }

        return input
            .summaryTransactionDataPublisher
            .withWeakCaptureOf(self)
            .map { $0.summaryDescription(data: $1) }
            .eraseToAnyPublisher()
    }

    var isMaxAmountButtonHiddenPublisher: AnyPublisher<Bool, Never> {
        guard let input else {
            assertionFailure("SendSummaryInput is not found")
            return Empty().eraseToAnyPublisher()
        }

        return input.isMaxAmountButtonHiddenPublisher
    }

    var areAmountFractionsHiddenPublisher: AnyPublisher<Bool, Never> {
        guard let sourceTokenInput else {
            assertionFailure("SendSourceTokenInput is not found")
            return Empty().eraseToAnyPublisher()
        }

        return sourceTokenInput
            .sourceTokenPublisher
            .compactMap(\.value)
            .flatMapLatest { $0.availableBalanceProvider.balanceTypePublisher }
            .map { balanceType in
                // Show the fractions only for a strictly positive balance.
                // While the balance is loading/empty/failed (`loaded == nil`) or zero
                // the buttons can't produce a meaningful amount, so hide them.
                guard let balance = balanceType.loaded else {
                    return true
                }

                return balance <= 0
            }
            .eraseToAnyPublisher()
    }

    var isNotificationButtonIsLoading: AnyPublisher<Bool, Never> {
        guard let input else {
            assertionFailure("SendSummaryInput is not found")
            return Empty().eraseToAnyPublisher()
        }

        return input.isNotificationButtonIsLoading
    }

    var isUpdatingPublisher: AnyPublisher<Bool, Never> {
        guard let input else {
            assertionFailure("SendSummaryInput is not found")
            return Empty().eraseToAnyPublisher()
        }

        return input.isUpdatingPublisher
    }

    var isActionInProcessing: AnyPublisher<Bool, Never> {
        guard let input else {
            assertionFailure("SendSummaryInput is not found")
            return Empty().eraseToAnyPublisher()
        }

        return input.isActionInProcessing
    }

    var isReadyToSendPublisher: AnyPublisher<Bool, Never> {
        guard let input else {
            assertionFailure("SendSummaryInput is not found")
            return Empty().eraseToAnyPublisher()
        }

        return input.isReadyToSendPublisher
    }

    var mainButtonStatePublisher: AnyPublisher<SwapSummaryViewModel.MainButtonState, Never> {
        guard let swapModelStateProvider else {
            assertionFailure("SwapModelStateProvider is not found")
            return Empty().eraseToAnyPublisher()
        }

        return swapModelStateProvider.statePublisher
            .filter { !$0.isLoading }
            .map { state -> SwapSummaryViewModel.MainButtonState in
                switch state {
                case .loaded(.transfer, _): .transfer
                default: .swap
                }
            }
            .removeDuplicates()
            .eraseToAnyPublisher()
    }

    func userDidRequestSwap() {
        output?.userDidRequestSwap()
    }

    // [REDACTED_TODO_COMMENT]
    func userDidRequestMaxAmount() {
        output?.userDidRequestMaxAmount()
    }

    func userDidRequestSourceAmount(fraction: SwapAmountFraction) {
        output?.userDidRequestSourceAmount(fraction: fraction)
    }

    func userDidRequestSwapSourceAndReceiveToken() {
        output?.userDidRequestSwapSourceAndReceiveToken()
    }
}

// MARK: - Private

private extension CommonSwapSummaryInteractor {
    private func summaryDescription(data: SendSummaryTransactionData?) -> AttributedString? {
        switch data {
        case .swap(let amount, let fee, let provider, let sourceTokenItem):
            return swapDescriptionBuilder.makeDescription(amount: amount, fee: fee, provider: provider, sourceTokenItem: sourceTokenItem)
        default:
            return nil
        }
    }
}
