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
    var initialFlowActionType: SendFlowActionType { get }
    var initialState: SendStepsManagerViewState { get }

    func performNext()
    func performBack()

    func performContinue()
    func performFinish()

    func set(output: SendStepsManagerOutput)
}
