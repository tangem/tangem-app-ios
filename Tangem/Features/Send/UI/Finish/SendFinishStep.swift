//
//  SendFinishStep.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine

class SendFinishStep {
    private let viewModel: SendFinishViewModel

    init(viewModel: SendFinishViewModel) {
        self.viewModel = viewModel
    }
}

// MARK: - SendStep

extension SendFinishStep: SendStep {
    var type: SendStepType { .finish(viewModel) }
    var sendStepViewAnimatable: any SendStepViewAnimatable { viewModel }

    var isValidPublisher: AnyPublisher<Bool, Never> {
        .just(output: true)
    }
}
