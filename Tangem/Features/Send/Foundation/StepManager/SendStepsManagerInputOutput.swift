//
//  SendStepsManagerInputOutput.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

protocol SendStepsManagerOutput: AnyObject {
    func update(step: SendStep)
    func update(flowActionType: SendFlowActionType)
    func setKeyboardActive(_ isActive: Bool)
    func stopSwapProvidersAutoUpdateTimer()
}
