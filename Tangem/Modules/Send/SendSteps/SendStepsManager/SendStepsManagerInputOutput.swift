//
//  SendStepsManagerInputOutput.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

protocol SendStepsManagerOutput: AnyObject {
    func update(state: SendStepsManagerViewState)
}

struct SendStepsManagerViewState {
    let step: SendStep
    let action: SendMainButtonType
    let backButtonVisible: Bool

    init(step: SendStep, action: SendMainButtonType, backButtonVisible: Bool = false) {
        self.step = step
        self.action = action
        self.backButtonVisible = backButtonVisible
    }
}
