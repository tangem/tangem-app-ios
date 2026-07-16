//
//  AddAndOrganizeRedesignEnvironment.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI

private struct AddAndOrganizeRedesignKey: EnvironmentKey {
    static let defaultValue = false
}

extension EnvironmentValues {
    var isAddAndOrganizeRedesignEnabled: Bool {
        get { self[AddAndOrganizeRedesignKey.self] }
        set { self[AddAndOrganizeRedesignKey.self] = newValue }
    }
}
