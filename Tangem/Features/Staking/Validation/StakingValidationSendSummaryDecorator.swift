//
//  StakingValidationSendSummaryDecorator.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine

/// Decorates SendSummaryInput to block the Send button during validation and when blocked.
final class StakingValidationSendSummaryDecorator: SendSummaryInput {
    private let decoratee: SendSummaryInput
    private let validationProvider: StakingValidationStateProvider

    init(
        decoratee: SendSummaryInput,
        validationProvider: StakingValidationStateProvider
    ) {
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

            switch validationState {
            case .idle, .validated, .warning:
                return true
            case .validating, .blocked:
                return false
            }
        }
        .eraseToAnyPublisher()
    }

    var isUpdatingPublisher: AnyPublisher<Bool, Never> {
        validationProvider.validationState
            .map { $0 == .validating }
            .eraseToAnyPublisher()
    }

    var summaryTransactionDataPublisher: AnyPublisher<SendSummaryTransactionData?, Never> {
        decoratee.summaryTransactionDataPublisher
    }
}
