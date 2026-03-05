//
//  StepsFlowViewModel.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import SwiftUI

@MainActor
final class StepsFlowViewModel: ObservableObject {
    typealias Step = StepsFlowStep

    @Published var currentStepId: Step.Id?

    var steps: [Step] { builder.steps }

    var progressValue: Double {
        guard let position = builder.currentPosition else { return 0 }
        return Double(position.index + 1) / Double(max(1, position.total))
    }

    private let builder: StepsFlowBuilder

    private var bag: Set<AnyCancellable> = []

    init(builder: StepsFlowBuilder) {
        self.builder = builder
        bind()
    }
}

// MARK: - Private methods

private extension StepsFlowViewModel {
    func bind() {
        builder.currentNodeSubject
            .withWeakCaptureOf(self)
            .sink { viewModel, node in
                viewModel.transact(step: node?.element)
            }
            .store(in: &bag)
    }

    func transact(step: Step?) {
        var transaction = Transaction()
        transaction.disablesAnimations = true

        withTransaction(transaction) {
            currentStepId = step?.id
        }
    }
}
