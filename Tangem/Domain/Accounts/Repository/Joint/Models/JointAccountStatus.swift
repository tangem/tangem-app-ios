//
//  JointAccountStatus.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import TangemMacro

/// Only ever moves forward.
/// - Warning: What the endpoint reports and what a stored record keeps are the case names themselves, so renaming one
/// rewrites the contract.
@RawCaseName
enum JointAccountStatus: Equatable {
    /// No address until every slot is taken.
    case pending
    /// Every slot taken and the address computed; the members check it and the creator activates.
    case confirming
    case active
    /// Named by the contract as a place to grow into; nothing puts an account here yet.
    case cancelled
    /// One the endpoint learnt to report after this version shipped. Kept as it arrived rather than turning the whole
    /// answer into a failure, since the backend goes on adding to the set.
    case unknown(String)
}

// MARK: - RawRepresentable, Codable

/// - Note: Reading and writing come free with the raw value, since the initialiser below never turns one down.
extension JointAccountStatus: RawRepresentable, Codable {
    init(rawValue: String) {
        self = Self.reportable.first { $0.rawValue == rawValue } ?? .unknown(rawValue)
    }

    /// - Warning: `rawCaseValue` answers `unknown` for the case of that name, dropping the very string it was read
    /// from, so only the cases this version knows are allowed to take their raw value from it.
    var rawValue: String {
        switch self {
        case .unknown(let rawValue): rawValue
        case .pending, .confirming, .active, .cancelled: rawCaseValue
        }
    }

    private static let reportable: [JointAccountStatus] = [.pending, .confirming, .active, .cancelled]
}
