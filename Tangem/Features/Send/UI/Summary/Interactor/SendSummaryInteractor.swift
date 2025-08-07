//
//  SendSummaryInteractor.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import BlockchainSdk

protocol SendSummaryInteractor: AnyObject {
    var transactionDescription: AnyPublisher<AttributedString?, Never> { get }
    var isNotificationButtonIsLoading: AnyPublisher<Bool, Never> { get }
}

class CommonSendSummaryInteractor {
    private weak var input: SendSummaryInput?
    private weak var output: SendSummaryOutput?

    private let sendDescriptionBuilder: SendTransactionSummaryDescriptionBuilder?
    private let stakingDescriptionBuilder: StakingTransactionSummaryDescriptionBuilder?

    init(
        input: SendSummaryInput,
        output: SendSummaryOutput,
        sendDescriptionBuilder: SendTransactionSummaryDescriptionBuilder?,
        stakingDescriptionBuilder: StakingTransactionSummaryDescriptionBuilder?,
    ) {
        self.input = input
        self.output = output
        self.sendDescriptionBuilder = sendDescriptionBuilder
        self.stakingDescriptionBuilder = stakingDescriptionBuilder
    }
}

extension CommonSendSummaryInteractor: SendSummaryInteractor {
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

    var isNotificationButtonIsLoading: AnyPublisher<Bool, Never> {
        guard let input else {
            assertionFailure("SendSummaryInput is not found")
            return Empty().eraseToAnyPublisher()
        }

        return input.isNotificationButtonIsLoading
    }
}

// MARK: - Private

private extension CommonSendSummaryInteractor {
    private func summaryDescription(data: SendSummaryTransactionData?) -> AttributedString? {
        switch data {
        case .none, .swap:
            return nil
        case .send(let amount, let fee):
            let description = sendDescriptionBuilder?.makeDescription(amount: amount, fee: fee)
            return description
        case .staking(let amount, let schedule):
            let description = stakingDescriptionBuilder?.makeDescription(amount: amount, schedule: schedule)
            return description
        }
    }
}
