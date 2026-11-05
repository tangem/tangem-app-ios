//
//  TokensManagementFlowEnvironment.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI

private struct TokensManagementFlowKey: EnvironmentKey {
    static let defaultValue = false
}

extension EnvironmentValues {
    var isInTokensManagementFlow: Bool {
        get { self[TokensManagementFlowKey.self] }
        set { self[TokensManagementFlowKey.self] = newValue }
    }
}
