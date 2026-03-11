//
//  SwapSummaryInteractor.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import Foundation

protocol SwapSummaryInteractor: AnyObject {
    var isUpdatingPublisher: AnyPublisher<Bool, Never> { get }
    var isReadyToSendPublisher: AnyPublisher<Bool, Never> { get }
    var isMaxAmountButtonHiddenPublisher: AnyPublisher<Bool, Never> { get }
    var transactionDescription: AnyPublisher<AttributedString?, Never> { get }
    var isNotificationButtonIsLoading: AnyPublisher<Bool, Never> { get }
    var isActionInProcessing: AnyPublisher<Bool, Never> { get }

    func userDidRequestSwapSourceAndReceiveToken()
    func userDidRequestMaxAmount()
    func userDidRequestSwap()
}

class CommonSwapSummaryInteractor {
    private weak var input: SwapSummaryInput?
    private weak var output: SwapSummaryOutput?

    private let swapDescriptionBuilder: SwapTransactionSummaryDescriptionBuilder
    private let sendWithSwapDescriptionBuilder: SendWithSwapTransactionSummaryDescriptionBuilder

    init(
        input: SwapSummaryInput,
        output: SwapSummaryOutput,
        receiveTokenAmountInput: SendReceiveTokenAmountInput?,
        swapDescriptionBuilder: SwapTransactionSummaryDescriptionBuilder,
        sendWithSwapDescriptionBuilder: SendWithSwapTransactionSummaryDescriptionBuilder,
    ) {
        self.input = input
        self.output = output
        self.swapDescriptionBuilder = swapDescriptionBuilder
        self.sendWithSwapDescriptionBuilder = sendWithSwapDescriptionBuilder
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

    func userDidRequestSwap() {
        output?.userDidRequestSwap()
    }

    func userDidRequestMaxAmount() {
        output?.userDidRequestMaxAmount()
    }

    func userDidRequestSwapSourceAndReceiveToken() {
        output?.userDidRequestSwapSourceAndReceiveToken()
    }
}

// MARK: - Private

private extension CommonSwapSummaryInteractor {
    private func summaryDescription(data: SendSummaryTransactionData?) -> AttributedString? {
        switch data {
        case .sendWithSwap(let amount, let fee, let provider):
            return sendWithSwapDescriptionBuilder.makeDescription(amount: amount, fee: fee, provider: provider)
        case .swap(let provider):
            return swapDescriptionBuilder.makeDescription(provider: provider)
        default:
            return nil
        }
    }
}
