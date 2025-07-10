//
//  ExpressAnalyticsLogger.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import TangemExpress

struct CommonExpressAnalyticsLogger: ExpressAnalyticsLogger {
    private let tokenItem: TokenItem

    init(tokenItem: TokenItem) {
        self.tokenItem = tokenItem
    }

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

    func logExpressError(_ error: ExpressAPIError, provider: ExpressProvider?) {
        var parameters: [Analytics.ParameterKey: String] = [
            .token: tokenItem.currencySymbol,
            .errorCode: error.errorCode.localizedDescription,
        ]

        parameters[.provider] = provider?.name

        Analytics.log(event: .swapNoticeExpressError, params: parameters)
    }

    func logSwapTransactionAnalyticsEvent(destination: String?) {
        var parameters: [Analytics.ParameterKey: String] = [.sendToken: tokenItem.currencySymbol]
        parameters[.receiveToken] = destination

        Analytics.log(event: .swapButtonSwap, params: parameters)
    }

    func logApproveTransactionAnalyticsEvent(policy: BSDKApprovePolicy, destination: String?) {
        var parameters: [Analytics.ParameterKey: String] = [.sendToken: tokenItem.currencySymbol]

        switch policy {
        case .specified:
            parameters[.type] = Analytics.ParameterValue.oneTransactionApprove.rawValue
        case .unlimited:
            parameters[.type] = Analytics.ParameterValue.unlimitedApprove.rawValue
        }

        parameters[.receiveToken] = destination

        Analytics.log(event: .swapButtonPermissionApprove, params: parameters)
    }

    func logApproveTransactionSentAnalyticsEvent(policy: BSDKApprovePolicy, signerType: String) {
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
            .token: tokenItem.currencySymbol,
            .blockchain: tokenItem.blockchain.displayName,
            .permissionType: permissionType.rawValue,
            .walletForm: signerType,
        ])
    }
}
