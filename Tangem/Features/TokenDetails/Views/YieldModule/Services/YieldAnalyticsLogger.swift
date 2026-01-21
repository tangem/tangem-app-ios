//
//  YieldAnalyticsLogger.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

enum YieldAnalyticsAction: String {
    case stop = "Stop"
    case approve = "Approve"
    case start = "Start"
}

enum YieldAnalyticsState: String {
    case enabled = "Enabled"
    case disabled = "Disabled"
}

protocol YieldAnalyticsLogger {
    func logTransactionSent(with result: TransactionDispatcherResult)
    func logStartEarningScreenOpened()
    func logEarningScreenInfoOpened()
    func logEarningButtonStart()
    func logEarningStopScreenOpened()
    func logEarningButtonStop()
    func logEarningButtonFeePolicy()
    func logEarningInProgressScreenOpened()
    func logEarningFundsEarned()
    func logEarningFundsWithdrawed()
    func logEarningEarnedFundsInfoOpened()
    func logEarningNoticeNotEnoughFeeShown()
    func logEarningNoticeApproveNeededShown()
    func logEarningButtonGiveApprove()
    func logEarningNoticeHighNetworkFeeShown()
    func logEarningErrors(action: YieldAnalyticsAction, error: Error)
    func logEarningNoticeAmountNotDepositedShown()
    func logEarningApyClicked(state: YieldAnalyticsState)

    func logYieldNoticeShown()
    func logYieldNoticeClicked()
}

final class CommonYieldAnalyticsLogger: YieldAnalyticsLogger {
    private let tokenItem: TokenItem
    private let userWalletId: UserWalletId

    init(tokenItem: TokenItem, userWalletId: UserWalletId) {
        self.tokenItem = tokenItem
        self.userWalletId = userWalletId
    }

    // MARK: - Earning analytics

    func logTransactionSent(with result: TransactionDispatcherResult) {
        Analytics.log(
            event: .transactionSent,
            params: [
                .source: Analytics.ParameterValue.yieldModuleSourceInfo.rawValue,
                .selectedHost: result.currentHost,
            ],
            analyticsSystems: .all,
            contextParams: .userWallet(userWalletId)
        )
    }

    func logStartEarningScreenOpened() {
        Analytics.log(
            event: .earningStartScreen,
            params: tokenBlockchainParams(),
            analyticsSystems: .all,
            contextParams: .userWallet(userWalletId)
        )
    }

    func logEarningScreenInfoOpened() {
        Analytics.log(
            event: .earningScreenInfoOpened,
            params: tokenBlockchainParams(),
            analyticsSystems: .all,
            contextParams: .userWallet(userWalletId)
        )
    }

    func logEarningButtonStart() {
        Analytics.log(event: .earningButtonStart, params: tokenBlockchainParams(), contextParams: .userWallet(userWalletId))
    }

    func logEarningStopScreenOpened() {
        Analytics.log(
            event: .earningStopScreen,
            params: tokenBlockchainParams(),
            analyticsSystems: .all,
            contextParams: .userWallet(userWalletId)
        )
    }

    func logEarningButtonStop() {
        Analytics.log(event: .earningButtonStop, params: tokenBlockchainParams(), contextParams: .userWallet(userWalletId))
    }

    func logEarningButtonFeePolicy() {
        Analytics.log(event: .earningButtonFeePolicy, params: tokenBlockchainParams(), contextParams: .userWallet(userWalletId))
    }

    func logEarningInProgressScreenOpened() {
        Analytics.log(
            event: .earningInProgressScreen,
            params: tokenBlockchainParams(),
            analyticsSystems: .all,
            contextParams: .userWallet(userWalletId)
        )
    }

    func logEarningFundsEarned() {
        Analytics.log(
            event: .earningFundsEarned,
            params: tokenBlockchainParams(),
            analyticsSystems: .all,
            contextParams: .userWallet(userWalletId)
        )
    }

    func logEarningFundsWithdrawed() {
        Analytics.log(
            event: .earningFundsWithdrawed,
            params: tokenBlockchainParams(),
            analyticsSystems: .all,
            contextParams: .userWallet(userWalletId)
        )
    }

    func logEarningEarnedFundsInfoOpened() {
        Analytics.log(event: .earningEarnedFundsInfo, params: tokenBlockchainParams(), contextParams: .userWallet(userWalletId))
    }

    func logEarningNoticeNotEnoughFeeShown() {
        Analytics.log(event: .earningNoticeNotEnoughFee, params: tokenBlockchainParams(), contextParams: .userWallet(userWalletId))
    }

    func logEarningNoticeApproveNeededShown() {
        Analytics.log(event: .earningNoticeApproveNeeded, params: tokenBlockchainParams(), contextParams: .userWallet(userWalletId))
    }

    func logEarningButtonGiveApprove() {
        Analytics.log(event: .earningButtonGiveApprove, params: tokenBlockchainParams(), contextParams: .userWallet(userWalletId))
    }

    func logEarningNoticeHighNetworkFeeShown() {
        Analytics.log(event: .earningNoticeHighNetworkFee, params: tokenBlockchainParams(), contextParams: .userWallet(userWalletId))
    }

    func logEarningErrors(action: YieldAnalyticsAction, error: Error) {
        Analytics.log(
            event: .earningErrors,
            params: [
                .action: action.rawValue,
                .errorCode: String(error.universalErrorCode),
                .errorDescription: error.localizedDescription,
            ],
            contextParams: .userWallet(userWalletId)
        )
    }

    func logEarningNoticeAmountNotDepositedShown() {
        Analytics.log(event: .earningNoticeAmountNotDeposited, params: tokenBlockchainParams())
    }

    func logEarningApyClicked(state: YieldAnalyticsState) {
        let stateParamValue = Analytics.ParameterValue(rawValue: state.rawValue)?.rawValue ?? ""
        let actionParamValue = Analytics.ParameterValue.yieldModuleSourceInfo.rawValue

        var paramsDict = tokenBlockchainParams()
        paramsDict[.state] = stateParamValue
        paramsDict[.action] = actionParamValue

        Analytics.log(event: .apyClicked, params: paramsDict, contextParams: .userWallet(userWalletId))
    }

    func logYieldNoticeShown() {
        Analytics.log(event: .mainNoticeYieldPromo, params: tokenBlockchainParams(), contextParams: .userWallet(userWalletId))
    }

    func logYieldNoticeClicked() {
        Analytics.log(event: .mainNoticeYieldPromoClicked, params: tokenBlockchainParams(), contextParams: .userWallet(userWalletId))
    }
}

extension CommonYieldAnalyticsLogger {
    func tokenBlockchainParams() -> [Analytics.ParameterKey: String] {
        [
            .token: SendAnalyticsHelper.makeAnalyticsTokenName(from: tokenItem),
            .blockchain: tokenItem.networkName,
        ]
    }
}
