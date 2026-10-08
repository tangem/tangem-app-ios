//
//  StepsFlowStepActiveEnvironment.swift
//  TangemUI
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI

private struct StepsFlowStepIsActiveEnvironmentKey: EnvironmentKey {
    static let defaultValue = true
}

public extension EnvironmentValues {
    /// Whether the enclosing StepsFlow step is the one currently on screen. Steps live side by
    /// side in a paging container and are mounted (and their appear lifecycle fires) before they
    /// scroll into view, so an input step must gate first-responder on this rather than on appear.
    var stepsFlowStepIsActive: Bool {
        get { self[StepsFlowStepIsActiveEnvironmentKey.self] }
        set { self[StepsFlowStepIsActiveEnvironmentKey.self] = newValue }
    }
}
