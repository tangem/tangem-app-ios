//
//  Character+.swift
//  TangemFoundation
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

public extension Character {
    var isASCIIHexDigit: Bool {
        isASCII && isHexDigit
    }
}
