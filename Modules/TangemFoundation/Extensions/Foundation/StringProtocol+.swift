//
//  StringProtocol+.swift
//  TangemFoundation
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

public extension StringProtocol {
    /// Just empty `""`
    static var empty: Self { "" }

    /// MINUS SIGN, Unicode U+2212.
    static var minusSign: Self { "−" }

    /// EN DASH, Unicode U+2013.
    static var enDashSign: Self { "–" }

    /// EM DASH, Unicode U+2014.
    static var emDashSign: Self { "—" }

    func caseInsensitiveContains(_ other: some StringProtocol) -> Bool {
        return range(of: other, options: .caseInsensitive) != nil
    }

    func caseInsensitiveHasPrefix(_ prefix: String) -> Bool {
        return range(of: prefix, options: [.anchored, .caseInsensitive]) != nil
    }

    /// I.e. `.orderedSame`.
    func caseInsensitiveEquals(to other: some StringProtocol) -> Bool {
        return caseInsensitiveCompare(other) == .orderedSame
    }

    /// I.e. `.orderedAscending`.
    func caseInsensitiveSmaller(than other: some StringProtocol) -> Bool {
        return caseInsensitiveCompare(other) == .orderedAscending
    }

    /// I.e. `.orderedDescending`.
    func caseInsensitiveGreater(than other: some StringProtocol) -> Bool {
        return caseInsensitiveCompare(other) == .orderedDescending
    }
}
