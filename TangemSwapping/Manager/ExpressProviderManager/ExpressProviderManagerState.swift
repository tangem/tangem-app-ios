//
//  ExpressProviderManagerState.swift
//  TangemSwapping
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

public enum ExpressProviderManagerState {
    case idle
    case error(Error, quote: ExpressQuote?)
    case restriction(_ restriction: ExpressRestriction, quote: ExpressQuote?)

    case permissionRequired(ExpressManagerState.PermissionRequired)
    case preview(ExpressManagerState.PreviewCEX)
    case ready(ExpressManagerState.Ready)

    public var error: Error? {
        switch self {
        case .idle, .permissionRequired, .restriction, .preview, .ready:
            return nil
        case .error(let error, _):
            return error
        }
    }

    public var quote: ExpressQuote? {
        switch self {
        case .idle:
            return nil
        case .error(_, let quote):
            return quote
        case .restriction(_, let quote):
            return quote
        case .permissionRequired(let state):
            return state.quote
        case .preview(let state):
            return state.quote
        case .ready(let state):
            return state.quote
        }
    }

    public var priority: Priority {
        if quote != nil {
            return .highest
        }

        switch self {
        case .permissionRequired:
            return .high
        case .restriction(.tooSmallAmount, _):
            return .medium
        case .restriction:
            return .low
        case .error:
            return .lowest
        default:
            return .low
        }
    }
}

public extension ExpressProviderManagerState {
    enum Priority: Int, Comparable {
        case lowest
        case low
        case medium
        case high
        case highest

        public static func < (lhs: Self, rhs: Self) -> Bool {
            lhs.rawValue < rhs.rawValue
        }
    }
}

extension ExpressProviderManagerState: CustomStringConvertible {
    public var description: String {
        switch self {
        case .idle:
            return "idle"
        case .error(let error, let quote):
            return "error \(error) quote \(String(describing: quote))"
        case .restriction(let restriction, let quote):
            return "restriction \(restriction) quote \(String(describing: quote))"
        case .permissionRequired(let permissionRequired):
            return "permissionRequired quote \(permissionRequired.quote)"
        case .preview(let previewCEX):
            return "previewCEX subtractFee: \(previewCEX.subtractFee) fee: \(previewCEX.fee) quote \(previewCEX.quote)"
        case .ready(let ready):
            return "ready fee: \(ready.fee) quote \(ready.quote)"
        }
    }
}
