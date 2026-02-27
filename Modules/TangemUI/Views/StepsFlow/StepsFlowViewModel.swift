//
//  StepsFlowViewModel.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine

final class StepsFlowViewModel: ObservableObject {
    let headStep: StepsFlowStep?
    let actionPublisher: AnyPublisher<StepsFlowAction, Never>

    var progressValue: Double {
        guard let position = builder.currentPosition else { return 0 }
        return Double(position.index + 1) / Double(max(1, position.total))
    }

    private let builder: StepsFlowBuilder

    init(builder: StepsFlowBuilder) {
        self.builder = builder
        headStep = builder.headNode?.element
        actionPublisher = builder.actionPublisher
            .dropFirst()
            .eraseToAnyPublisher()
    }
}
