//
//  Analytics+JointAccount.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation
import BlockchainSdk
import TangemMacro

extension Analytics {
    enum JointAccountCreationSource: String {
        case addAccount = "Add Account"
        case mainScreen = "Main Screen"
    }

    enum JointAccountFlow: String {
        case create = "Create"
        case join = "Join"
    }

    enum JointAccountErrorSource: String {
        case create = "Create"
        case join = "Join"
        case createOperation = "Create Operation"
        case sign = "Sign"
        case decline = "Decline"
        case delete = "Delete"

        init(flow: JointAccountFlow) {
            switch flow {
            case .create: self = .create
            case .join: self = .join
            }
        }
    }

    enum JointAccountFakedoorSource: String {
        case walletConnect = "WalletConnect"
        case transfer = "Transfer"
        case mainScreenSwap = "Main Screen Swap"
    }

    enum JointAccountFakedoorAction: String {
        case connect = "Connect"
        case swap = "Swap"
        case swapAndSend = "Swap&Send"
        case sell = "Sell"
    }
}

// MARK: - Logging

extension Analytics {
    static func logJointAccountError(source: JointAccountErrorSource, error: Error) {
        log(event: .jointAccountError, params: JointAccountErrorAnalyticsParameters(source: source, error: error).build())
    }

    static func logJointAccountAccountsLimitReached(flow: JointAccountFlow) {
        log(event: .jointAccountNoticeAccountsLimitReached, params: [.source: flow.rawValue])
    }

    static func logJointAccountFakedoorPopupDisplayed(
        source: JointAccountFakedoorSource,
        action: JointAccountFakedoorAction,
        tokenItem: TokenItem?
    ) {
        var params: [ParameterKey: String] = [
            .source: source.rawValue,
            .action: action.rawValue,
        ]

        if let tokenItem {
            params[.blockchain] = tokenItem.blockchain.displayName
            params[.token] = tokenItem.currencySymbol
        }

        log(event: .jointAccountFakedoorPopupDisplayed, params: params)
    }
}

// MARK: - Error parameters

struct JointAccountErrorAnalyticsParameters {
    let source: Analytics.JointAccountErrorSource
    let error: Error

    func build() -> [Analytics.ParameterKey: String] {
        let cause = Self.cause(of: error)

        var params: [Analytics.ParameterKey: String] = [
            .source: source.rawValue,
            .errorMessage: Self.message(of: cause),
        ]

        if let code = Self.code(of: cause) {
            params[.errorCode] = code
        }

        return params
    }
}

private extension JointAccountErrorAnalyticsParameters {
    static func cause(of error: Error) -> Error {
        switch error {
        case AccountEditError.unknownError(let underlying):
            cause(of: underlying)
        case let sendTxError as SendTxError:
            cause(of: sendTxError.error)
        case let wrapper as UniversalErrorWrapper:
            cause(of: wrapper.underlyingError)
        default:
            error
        }
    }

    static func code(of error: Error) -> String? {
        switch error {
        case let apiError as TangemAPIError:
            apiError.reasonCode ?? "\(apiError.code.rawValue)"
        case JointOperationError.refused(let refusal):
            refusal.reasonCode
        default:
            nil
        }
    }

    static func message(of error: Error) -> String {
        if let error = error as? RawCaseNameRepresentable {
            return "\(type(of: error)).\(error.rawCaseValue)"
        }

        if let errorDescription = (error as? LocalizedError)?.errorDescription {
            return errorDescription
        }

        return (error as NSError).localizedDescription
    }
}
