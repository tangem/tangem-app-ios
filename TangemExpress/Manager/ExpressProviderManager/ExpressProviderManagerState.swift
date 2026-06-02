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
    case revokeAndPermissionRequired(ExpressProviderManagerState.PermissionRequired)
    case cexPreview(ExpressProviderManagerState.CEXPreview)
    case dexPreview(ExpressProviderManagerState.DEXPreview)

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
        case .revokeAndPermissionRequired(let state):
            return state.quote
        case .cexPreview(let state):
            return state.quote
        case .dexPreview(let state):
            return state.quote
        }
    }

    public var isError: Bool {
        switch self {
        case .idle, .permissionRequired, .revokeAndPermissionRequired, .restriction, .cexPreview, .dexPreview:
            return false
        case .error:
            return true
        }
    }

    public var isShowable: Bool {
        switch self {
        case .permissionRequired, .revokeAndPermissionRequired, .restriction, .cexPreview, .dexPreview:
            return true
        case .idle, .error:
            return false
        }
    }

    public var isPermissionRequired: Bool {
        switch self {
        case .permissionRequired, .revokeAndPermissionRequired:
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
        public let approvalFlow: ApprovalFlow
        public let fee: Fee
        public let quote: ExpressQuote
    }

    enum ApprovalFlow {
        /// Single approve tx
        case approve
        /// Revoke existing allowance, then approve. Required for tokens like USDT on Ethereum.
        case revokeAndApprove(revokeData: ApproveTransactionData, feeUnit: Fee)
    }

    struct CEXPreview {
        public let provider: ExpressProvider
        public let subtractFee: Decimal
        public let quote: ExpressQuote
        public let fee: Fee
    }

    struct DEXPreview {
        public let provider: ExpressProvider
        public let data: ExpressTransactionData
        public let fee: Fee
        public let quote: ExpressQuote
        public let requiredApprove: PermissionRequired?
    }
}

// MARK: - Factory

extension ExpressProviderManagerState {
    static func mapError(_ apiError: ExpressAPIError, quote: ExpressQuote? = nil, currencySymbol: String = "") -> Self {
        guard let amount = apiError.value?.amount else {
            return .error(apiError, quote: quote)
        }

        switch apiError.errorCode {
        case .exchangeTooSmallAmountError:
            return .restriction(.tooSmallAmount(amount, currencySymbol: currencySymbol), quote: quote)
        case .exchangeTooBigAmountError:
            return .restriction(.tooBigAmount(amount, currencySymbol: currencySymbol), quote: quote)
        default:
            return .error(apiError, quote: quote)
        }
    }
}

// MARK: - CustomStringConvertible

extension ExpressProviderManagerState: CustomStringConvertible {
    public var description: String {
        switch self {
        case .idle:
            return "idle"
        case .error(let error, let quote):
            return "error \(error) quote \(String(describing: quote))"
        case .restriction(let restriction, let quote):
            return "restriction \(restriction) quote \(String(describing: quote))"
        case .permissionRequired(let state):
            return "permissionRequired quote \(state.quote)"
        case .revokeAndPermissionRequired(let state):
            return "revokeAndPermissionRequired quote \(state.quote)"
        case .cexPreview(let cexPreview):
            return "cexPreview subtractFee: \(cexPreview.subtractFee), quote \(cexPreview.quote)"
        case .dexPreview(let dexPreview):
            return "dexPreview quote \(dexPreview.quote)"
        }
    }
}
