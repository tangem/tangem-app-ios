//
//  RawCaseNameRepresentable.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

public protocol RawCaseNameRepresentable {
    var rawCaseValue: String { get }
}

public extension RawCaseNameRepresentable {
    func isEqualByRawCaseIdentifier(to another: Self) -> Bool {
        rawCaseValue == another.rawCaseValue
    }
}

// MARK: - Identifiable+

public extension Identifiable where Self: RawCaseNameRepresentable {
    var id: String { rawCaseValue }
}
