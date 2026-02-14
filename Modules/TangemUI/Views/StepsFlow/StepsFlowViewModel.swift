//
//  StepsFlowViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine

final class StepsFlowViewModel: ObservableObject {
    var actions: AnyPublisher<StepsFlowAction, Never> {
        builder.actionPublisher
            .compactMap { $0 }
            .eraseToAnyPublisher()
    }

    var progressValue: Double {
        guard
            let position = builder.currentPosition,
            position.total > 0
        else {
            return 0
        }

        return Double(position.index + 1) / Double(position.total)
    }

    private let builder: StepsFlowBuilder

    init(builder: StepsFlowBuilder) {
        self.builder = builder
    }
}
