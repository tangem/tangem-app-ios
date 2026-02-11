//
//  ExpressProviderManagerState.swift
//  TangemExpress
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk

public enum ExpressProviderManagerState {
    case idle
    case error(Error, quote: ExpressQuote?)
    case restriction(_ restriction: ExpressRestriction, quote: ExpressQuote?)

    case permissionRequired(ExpressProviderManagerState.PermissionRequired)
    case preview(ExpressProviderManagerState.PreviewCEX)
    case ready(ExpressProviderManagerState.Ready)

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

    public var isError: Bool {
        switch self {
        case .idle, .permissionRequired, .restriction, .preview, .ready:
            return false
        case .error:
            return true
        }
    }

    public var isPermissionRequired: Bool {
        switch self {
        case .permissionRequired:
            return true
        default:
            return false
        }
    }
}

public extension ExpressProviderManagerState {
    struct PermissionRequired {
        public let provider: ExpressProvider
        public let policy: ApprovePolicy
        public let data: ApproveTransactionData
        public let quote: ExpressQuote
    }

    struct PreviewCEX {
        public let provider: ExpressProvider
        public let subtractFee: Decimal
        public let quote: ExpressQuote
    }

    struct Ready {
        public let provider: ExpressProvider
        public let data: ExpressTransactionData
        public let quote: ExpressQuote
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
            return "previewCEX subtractFee: \(previewCEX.subtractFee), quote \(previewCEX.quote)"
        case .ready(let ready):
            return "quote \(ready.quote)"
        }
    }
}
