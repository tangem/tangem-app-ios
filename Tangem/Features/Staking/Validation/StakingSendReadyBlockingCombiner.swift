//
//  StakingSendReadyBlockingCombiner.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine

/// Combines SendSummaryInput's isReadyToSendPublisher with StakingValidationStateProvider
/// to block the Send button when validation state is blocked.
final class StakingSendReadyBlockingCombiner: SendSummaryInput {
    private let decoratee: SendSummaryInput
    private let validationProvider: StakingValidationStateProvider

    init(decoratee: SendSummaryInput, validationProvider: StakingValidationStateProvider) {
        self.decoratee = decoratee
        self.validationProvider = validationProvider
    }

    var isReadyToSendPublisher: AnyPublisher<Bool, Never> {
        Publishers.CombineLatest(
            decoratee.isReadyToSendPublisher,
            validationProvider.validationState
        )
        .map { isReady, validationState in
            guard isReady else { return false }
            return validationState != .blocked
        }
        .eraseToAnyPublisher()
    }

    var summaryTransactionDataPublisher: AnyPublisher<SendSummaryTransactionData?, Never> {
        decoratee.summaryTransactionDataPublisher
    }
}
