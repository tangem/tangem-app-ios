//
//  PolymarketBuilderCode.swift
//  TangemPolymarket
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

enum PolymarketBuilderCode {
    static let field = "builderCode"

    static func isWellFormed(_ code: String) -> Bool {
        guard code.hasHexPrefixStrictCheck() else { return false }

        let digits = code.removeHexPrefix()

        return digits.count == Constants.digitCount && digits.allSatisfy(\.isHexDigit)
    }
}

// MARK: - Constants

private extension PolymarketBuilderCode {
    enum Constants {
        static let digitCount = 64
    }
}
