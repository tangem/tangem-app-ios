//
//  ExpressAnalyticsLogger.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk
import TangemExpress
import TangemFoundation

struct CommonExpressInteractorAnalyticsLogger {
    private let tokenItem: TokenItem

    init(tokenItem: TokenItem) {
        self.tokenItem = tokenItem
    }
}

// MARK: - ExpressAnalyticsLogger

extension CommonExpressInteractorAnalyticsLogger: ExpressInteractorAnalyticsLogger {
    func logExpressError(_ error: Error, provider: ExpressProvider?) {
        var parameters: [Analytics.ParameterKey: String] = [
            .token: tokenItem.currencySymbol,
        ]

        if let provider = provider?.name {
            parameters[.provider] = provider
        }

        switch error {
        case let error as ExpressAPIError:
            parameters[.errorCode] = error.errorCode.localizedDescription
        default:
            let universalError = error.toUniversalError()

            parameters[.errorCode] = "\(universalError.errorCode)"
            parameters[.errorDescription] = universalError.errorDescription
        }

        Analytics.log(event: .swapNoticeExpressError, params: parameters)
    }

    func logSwapTransactionAnalyticsEvent(destination: TokenItem) {
        let parameters: [Analytics.ParameterKey: String] = [
            .sendToken: tokenItem.currencySymbol,
            .receiveToken: destination.currencySymbol,
        ]

        Analytics.log(event: .swapButtonSwap, params: parameters)
    }

    func logApproveTransactionAnalyticsEvent(policy: ApprovePolicy, provider: ExpressProvider, destination: TokenItem) {
        var parameters: [Analytics.ParameterKey: String] = [
            .sendToken: tokenItem.currencySymbol,
            .provider: provider.name,
            .receiveToken: destination.currencySymbol,
        ]

        switch policy {
        case .specified:
            parameters[.type] = Analytics.ParameterValue.oneTransactionApprove.rawValue
        case .unlimited:
            parameters[.type] = Analytics.ParameterValue.unlimitedApprove.rawValue
        }

        Analytics.log(event: .swapButtonPermissionApprove, params: parameters)
    }

    func logApproveTransactionSentAnalyticsEvent(policy: BSDKApprovePolicy, signerType: String, currentProviderHost: String) {
        let permissionType: Analytics.ParameterValue = {
            switch policy {
            case .specified:
                return .oneTransactionApprove
            case .unlimited:
                return .unlimitedApprove
            }
        }()

        Analytics.log(event: .transactionSent, params: [
            .source: Analytics.ParameterValue.transactionSourceApprove.rawValue,
            .feeType: Analytics.ParameterValue.transactionFeeMax.rawValue,
            .token: SendAnalyticsHelper.makeAnalyticsTokenName(from: tokenItem),
            .blockchain: tokenItem.blockchain.displayName,
            .permissionType: permissionType.rawValue,
            .walletForm: signerType,
            .selectedHost: currentProviderHost,
        ])
    }
}

// MARK: - ExpressAnalyticsLogger

extension CommonExpressInteractorAnalyticsLogger: ExpressAnalyticsLogger {
    func bestProviderSelected(_ provider: ExpressAvailableProvider) {
        guard provider.provider.id.lowercased() == "changelly",
              provider.provider.recommended == true else {
            return
        }

        Analytics.log(
            .promoChangellyActivity,
            params: [.state: provider.isBest ? .native : .recommended]
        )
    }

    func logAppError(_ error: any Error, provider: ExpressProvider) {
        Analytics.log(
            event: .onrampAppErrors,
            params: [
                .token: tokenItem.currencySymbol,
                .provider: provider.name,
                .errorDescription: error.localizedDescription,
            ]
        )
    }

    func logExpressAPIError(_ error: ExpressAPIError, provider: ExpressProvider, paymentMethod: OnrampPaymentMethod) {
        Analytics.log(
            event: .onrampErrors,
            params: [
                .token: tokenItem.currencySymbol,
                .provider: provider.name,
                .errorCode: error.errorCode.rawValue.description,
                .paymentMethod: paymentMethod.name,
            ]
        )
    }
}
