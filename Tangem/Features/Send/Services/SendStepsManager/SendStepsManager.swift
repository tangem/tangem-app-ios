//
//  SendStepsManager.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine

protocol SendStepsManager {
    var initialKeyboardState: Bool { get }
    var initialFlowActionType: SendFlowActionType { get }
    var initialState: SendStepsManagerViewState { get }

    var shouldShowDismissAlert: Bool { get }

    func resetFlow()

    func performNext()
    func performBack()
    func performContinue()
    func performFinish()

    func set(output: SendStepsManagerOutput)
}

extension SendStepsManager {
    func resetFlow() {
        assertionFailure("Reset flow not implemented")
    }
}
