//
//  YieldAnalyticsLogger.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

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
}

final class CommonYieldAnalyticsLogger: YieldAnalyticsLogger {
    private let tokenItem: TokenItem

    init(tokenItem: TokenItem) {
        self.tokenItem = tokenItem
    }

    // MARK: - Earning analytics

    func logTransactionSent(with result: TransactionDispatcherResult) {
        Analytics.log(
            event: .transactionSent,
            params: [
                .source: Analytics.ParameterValue.yieldModuleSourceInfo.rawValue,
                .selectedHost: result.currentHost,
            ]
        )
    }

    func logStartEarningScreenOpened() {
        Analytics.log(event: .earningStartScreen, params: tokenBlockchainParams())
    }

    func logEarningScreenInfoOpened() {
        Analytics.log(event: .earningScreenInfoOpened, params: tokenBlockchainParams())
    }

    func logEarningButtonStart() {
        Analytics.log(event: .earningButtonStart, params: tokenBlockchainParams())
    }

    func logEarningStopScreenOpened() {
        Analytics.log(event: .earningStopScreen, params: tokenBlockchainParams())
    }

    func logEarningButtonStop() {
        Analytics.log(event: .earningButtonStop, params: tokenBlockchainParams())
    }

    func logEarningButtonFeePolicy() {
        Analytics.log(event: .earningButtonFeePolicy, params: tokenBlockchainParams())
    }

    func logEarningInProgressScreenOpened() {
        Analytics.log(event: .earningInProgressScreen, params: tokenBlockchainParams())
    }

    func logEarningFundsEarned() {
        Analytics.log(event: .earningFundsEarned, params: tokenBlockchainParams())
    }

    func logEarningFundsWithdrawed() {
        Analytics.log(event: .earningFundsWithdrawed, params: tokenBlockchainParams())
    }

    func logEarningEarnedFundsInfoOpened() {
        Analytics.log(event: .earningEarnedFundsInfo, params: tokenBlockchainParams())
    }

    func logEarningNoticeNotEnoughFeeShown() {
        Analytics.log(event: .earningNoticeNotEnoughFee, params: tokenBlockchainParams())
    }

    func logEarningNoticeApproveNeededShown() {
        Analytics.log(event: .earningNoticeApproveNeeded, params: tokenBlockchainParams())
    }

    func logEarningButtonGiveApprove() {
        Analytics.log(event: .earningButtonGiveApprove, params: tokenBlockchainParams())
    }

    func logEarningNoticeHighNetworkFeeShown() {
        Analytics.log(event: .earningNoticeHighNetworkFee, params: tokenBlockchainParams())
    }

    func logEarningErrors(action: YieldAnalyticsAction, error: Error) {
        Analytics.log(
            event: .earningErrors,
            params: [
                .action: action.rawValue,
                .errorCode: String(error.universalErrorCode),
                .errorDescription: error.localizedDescription,
            ]
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

        Analytics.log(event: .apyClicked, params: paramsDict)
    }
}

extension CommonYieldAnalyticsLogger {
    func tokenBlockchainParams() -> [Analytics.ParameterKey: String] {
        [
            .token: SendAnalyticsHelper.makeAnalyticsTokenName(from: tokenItem),
            .blockchain: tokenItem.blockchain.displayName,
        ]
    }
}
