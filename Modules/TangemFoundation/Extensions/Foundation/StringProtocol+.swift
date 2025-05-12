//
//  StringProtocol+.swift
//  TangemFoundation
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

public extension StringProtocol {
    func caseInsensitiveContains(_ other: some StringProtocol) -> Bool {
        return range(of: other, options: .caseInsensitive) != nil
    }

    func caseInsensitiveHasPrefix(_ prefix: String) -> Bool {
        return range(of: prefix, options: [.anchored, .caseInsensitive]) != nil
    }

    func caseInsensitiveEquals(to other: some StringProtocol) -> Bool {
        return caseInsensitiveCompare(other) == .orderedSame
    }
}
