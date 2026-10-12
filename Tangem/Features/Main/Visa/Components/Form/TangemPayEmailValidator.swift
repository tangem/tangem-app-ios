//
//  TangemPayEmailValidator.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

enum TangemPayEmailValidator {
    static func isValid(_ value: String) -> Bool {
        value.range(of: Constants.pattern, options: .regularExpression) != nil
    }
}

// MARK: - Constants

private extension TangemPayEmailValidator {
    enum Constants {
        static let pattern = "^[^\\s@]+@[^\\s@]+\\.[^\\s@]+$"
    }
}
