//
//  SendSummaryInteractor.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemLocalization
import TangemFoundation

protocol SendSummaryInteractor: AnyObject {
    var isUpdatingPublisher: AnyPublisher<Bool, Never> { get }
    var isReadyToSendPublisher: AnyPublisher<Bool, Never> { get }
    var transactionDescription: AnyPublisher<AttributedString?, Never> { get }
    var isNotificationButtonIsLoading: AnyPublisher<Bool, Never> { get }
}

class CommonSendSummaryInteractor {
    private weak var input: SendSummaryInput?
    private weak var output: SendSummaryOutput?
    private weak var swapModelStateProvider: SwapModelStateProvider?
    private weak var validationStateProvider: StakingValidationStateProvider?

    private let transactionSummaryDescriptionBuilderProvider: TransactionSummaryDescriptionBuilderProvider

    init(
        input: SendSummaryInput,
        output: SendSummaryOutput,
        swapModelStateProvider: SwapModelStateProvider?,
        validationStateProvider: StakingValidationStateProvider?,
        transactionSummaryDescriptionBuilderProvider: TransactionSummaryDescriptionBuilderProvider
    ) {
        self.input = input
        self.output = output
        self.swapModelStateProvider = swapModelStateProvider
        self.validationStateProvider = validationStateProvider
        self.transactionSummaryDescriptionBuilderProvider = transactionSummaryDescriptionBuilderProvider
    }
}

extension CommonSendSummaryInteractor: SendSummaryInteractor {
    var transactionDescription: AnyPublisher<AttributedString?, Never> {
        guard let input else {
            assertionFailure("SendSummaryInput is not found")
            return .empty
        }

        return input
            .summaryTransactionDataPublisher
            .withWeakCaptureOf(self)
            .map { $0.summaryDescription(data: $1) }
            .eraseToAnyPublisher()
    }

    var isNotificationButtonIsLoading: AnyPublisher<Bool, Never> {
        guard let input else {
            assertionFailure("SendSummaryInput is not found")
            return .empty
        }

        return input.isNotificationButtonIsLoading
    }

    var isUpdatingPublisher: AnyPublisher<Bool, Never> {
        if let swapModelStateProvider {
            return swapModelStateProvider
                .statePublisher
                .filter { $0.filter(loading: [.autoupdate]) }
                .map { $0.isLoading }
                .eraseToAnyPublisher()
        }

        if let validationStateProvider {
            return validationStateProvider.validationState
                .map { $0 == .validating }
                .eraseToAnyPublisher()
        }

        return .empty
    }

    var isReadyToSendPublisher: AnyPublisher<Bool, Never> {
        guard let input else {
            assertionFailure("SendSummaryInput is not found")
            return .empty
        }

        return input.isReadyToSendPublisher
    }
}

// MARK: - Private

private extension CommonSendSummaryInteractor {
    private func summaryDescription(data: SendSummaryTransactionData?) -> AttributedString? {
        switch data {
        case .none:
            return nil
        case .staking(let amount, let schedule):
            return transactionSummaryDescriptionBuilderProvider
                .makeStakingTransactionSummaryDescriptionBuilder()
                .makeDescription(amount: amount, schedule: schedule)
        case .send(let amount, let fee):
            return transactionSummaryDescriptionBuilderProvider
                .makeSendTransactionSummaryDescriptionBuilder()
                .makeDescription(amount: amount, fee: fee)
        case .swap(let amount, let fee, let provider):
            return transactionSummaryDescriptionBuilderProvider
                .makeSendWithSwapTransactionSummaryDescriptionBuilder()
                .makeDescription(amount: amount, fee: fee, provider: provider)
        }
    }
}
