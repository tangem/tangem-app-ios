//
//  TokenSelectorView+Environment.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI

private struct TokenSelectorShowsSeparatorsKey: EnvironmentKey {
    static let defaultValue = true
}

private struct TokenSelectorHidesWalletNameHeaderKey: EnvironmentKey {
    static let defaultValue = false
}

extension EnvironmentValues {
    var tokenSelectorShowsSeparators: Bool {
        get { self[TokenSelectorShowsSeparatorsKey.self] }
        set { self[TokenSelectorShowsSeparatorsKey.self] = newValue }
    }

    var tokenSelectorHidesWalletNameHeader: Bool {
        get { self[TokenSelectorHidesWalletNameHeaderKey.self] }
        set { self[TokenSelectorHidesWalletNameHeaderKey.self] = newValue }
    }
}
