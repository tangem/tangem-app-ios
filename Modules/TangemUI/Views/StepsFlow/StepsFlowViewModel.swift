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
    @Published private var stepTitles: [Step.Id: String?] = [:]
    @Published private var stepLeadingItems: [Step.Id: StepsFlowNavBarItem?] = [:]
    @Published private var stepTrailingItems: [Step.Id: StepsFlowNavBarItem?] = [:]
    @Published private var stepLoadingStates: [Step.Id: Bool] = [:]

    var steps: [Step] { builder.steps }

    var progressValue: Double {
        guard let position = builder.currentPosition else { return 0 }
        return Double(position.index + 1) / Double(max(1, position.total))
    }

    var currentTitle: String? { currentStepId.flatMap { stepTitles[$0] } ?? nil }
    var currentLeadingItem: StepsFlowNavBarItem? { currentStepId.flatMap { stepLeadingItems[$0] } ?? nil }
    var currentTrailingItem: StepsFlowNavBarItem? { currentStepId.flatMap { stepTrailingItems[$0] } ?? nil }
    var currentIsLoading: Bool { currentStepId.flatMap { stepLoadingStates[$0] } ?? false }

    private let builder: StepsFlowBuilder

    private var bag: Set<AnyCancellable> = []

    init(builder: StepsFlowBuilder) {
        self.builder = builder
        bind()
    }

    func update(stepId: Step.Id, title: String?) {
        stepTitles[stepId] = title
    }

    func update(stepId: Step.Id, leadingItem: StepsFlowNavBarItem?) {
        stepLeadingItems[stepId] = leadingItem
    }

    func update(stepId: Step.Id, trailingItem: StepsFlowNavBarItem?) {
        stepTrailingItems[stepId] = trailingItem
    }

    func update(stepId: Step.Id, isLoading: Bool) {
        stepLoadingStates[stepId] = isLoading
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
