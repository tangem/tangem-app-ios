//
//  SendNewFinishStep.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import Combine

class SendNewFinishStep {
    private let viewModel: SendNewFinishViewModel

    init(viewModel: SendNewFinishViewModel) {
        self.viewModel = viewModel
    }
}

// MARK: - SendStep

extension SendNewFinishStep: SendStep {
    var title: String? { nil }

    var type: SendStepType { .newFinish(viewModel) }

    var navigationLeadingViewType: SendStepNavigationLeadingViewType? { .none }
    var navigationTrailingViewType: SendStepNavigationTrailingViewType? { .closeButton }

    var sendStepViewAnimatable: any SendStepViewAnimatable { viewModel }

    var isValidPublisher: AnyPublisher<Bool, Never> {
        .just(output: true)
    }
}
