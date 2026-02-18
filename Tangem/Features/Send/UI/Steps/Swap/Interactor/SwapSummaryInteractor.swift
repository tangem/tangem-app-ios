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

    func userDidRequestSwapSourceAndReceiveToken()
    func userDidRequestMaxAmount()
    func userDidRequestSwap()
}

class CommonSwapSummaryInteractor {
    private weak var input: SwapSummaryInput?
    private weak var output: SwapSummaryOutput?

    private let sendDescriptionBuilder: SendTransactionSummaryDescriptionBuilder
    private let swapDescriptionBuilder: SwapTransactionSummaryDescriptionBuilder
    private let stakingDescriptionBuilder: StakingTransactionSummaryDescriptionBuilder

    init(
        input: SwapSummaryInput,
        output: SwapSummaryOutput,
        receiveTokenAmountInput: SendReceiveTokenAmountInput?,
        sendDescriptionBuilder: SendTransactionSummaryDescriptionBuilder,
        swapDescriptionBuilder: SwapTransactionSummaryDescriptionBuilder,
        stakingDescriptionBuilder: StakingTransactionSummaryDescriptionBuilder
    ) {
        self.input = input
        self.output = output
        self.sendDescriptionBuilder = sendDescriptionBuilder
        self.swapDescriptionBuilder = swapDescriptionBuilder
        self.stakingDescriptionBuilder = stakingDescriptionBuilder
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
        case .none:
            return nil
        case .staking(let amount, let schedule):
            let description = stakingDescriptionBuilder.makeDescription(amount: amount, schedule: schedule)
            return description
        case .send(let amount, let fee):
            let description = sendDescriptionBuilder.makeDescription(amount: amount, fee: fee)
            return description
        case .swap(let amount, let fee, let provider):
            let description = swapDescriptionBuilder.makeDescription(amount: amount, fee: fee, provider: provider)
            return description
        }
    }
}
