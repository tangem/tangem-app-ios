//
//  TestFeature.swift
//  TangemUITests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

/// Test-side mirror for a subset of the app target's `Feature` cases that UI tests
/// currently need to flip via launch arguments. Extend as new toggles are exercised
/// in tests; the app side accepts any `Feature` rawValue via `-uitest-feature-<rawValue>-on/off`.
enum TestFeature: String, CaseIterable {
    case redesign
    case yieldModuleUpdate
}
