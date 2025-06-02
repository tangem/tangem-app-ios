//
//  SendNewSummaryStep.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import SwiftUI

class SendNewSummaryStep {
    private let viewModel: SendNewSummaryViewModel
    private let input: SendSummaryInput
    private let _title: String?
    private let _subtitle: String?

    init(
        viewModel: SendNewSummaryViewModel,
        input: SendSummaryInput,
        title: String?,
        subtitle: String?
    ) {
        self.viewModel = viewModel
        self.input = input
        _title = title
        _subtitle = subtitle
    }

    func set(router: SendSummaryStepsRoutable) {
        viewModel.router = router
    }
}

// MARK: - SendStep

extension SendNewSummaryStep: SendStep {
    var title: String? { _title }

    var type: SendStepType { .newSummary(viewModel) }

    var sendStepViewAnimatable: any SendStepViewAnimatable { viewModel }

    var isValidPublisher: AnyPublisher<Bool, Never> {
        input.isReadyToSendPublisher.eraseToAnyPublisher()
    }
}
