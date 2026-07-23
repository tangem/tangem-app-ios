//
//  StakingSendAnalyticsLoggerMock.swift
//  TangemTests
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk
import TangemExpress
import TangemStaking
@testable import Tangem

final class StakingSendAnalyticsLoggerMock: StakingSendAnalyticsLogger {
    private(set) var noticeNotEnoughFeeCalls = 0

    // MARK: - StakingSendAnalyticsLogger

    func setup(stakingTargetsInput: StakingTargetsInput) {}
    func logNoticeUninitializedAddress() {}

    func logNoticeNotEnoughFee() {
        noticeNotEnoughFeeCalls += 1
    }

    func logErrorSumLimit(errorMessage: String) {}

    // MARK: - StakingAnalyticsLogger

    func logError(_ error: any Error, currencySymbol: String) {}

    // MARK: - StakingManagementModelAnalyticsLogger

    func logStakingTransactionRejected(error: SendTxError) {}
    func logStakingTransactionSent(amount: SendAmount?, fee: FeeOption, signerType: String, currentProviderHost: String) {}

    // MARK: - StakingValidationAnalyticsLogger

    func logSuccess() {}
    func logLocalError(_ error: StakingTransactionValidationError) {}
    func logRemoteError(_ error: RemoteStakingValidationError) {}
    func logNoRawTransactions() {}

    // MARK: - SendBaseViewAnalyticsLogger

    func logSendBaseViewOpened() {}
    func logRequestSupport() {}
    func logMainActionButton(type: SendMainButtonType, flow: SendFlowActionType) {}
    func logCloseButton(stepType: SendStepType, isAvailableToAction: Bool) {}

    // MARK: - SendAmountAnalyticsLogger

    func logTapMaxAmount() {}
    func logTapConvertToAnotherToken() {}
    func logAmountStepOpened() {}
    func logAmountStepReopened() {}
    func logSwapErrorExpressQuote(screen: Analytics.ParameterValue, errorDescription: String) {}
    func logSendWithSwapAmountScreenOpened(rateType: ExpressProviderRateType?) {}

    // MARK: - SendTargetsAnalyticsLogger

    func logStakingTargetChosen() {}

    // MARK: - SendSummaryAnalyticsLogger

    func logUserDidTapOnValidator() {}
    func logUserDidTapOnProvider() {}
    func logSummaryStepOpened() {}

    // MARK: - SendFinishAnalyticsLogger

    func logFinishStepOpened() {}
    func logShareButton() {}
    func logExploreButton() {}

    // MARK: - SendApproveAnalyticsLogger

    func logPermissionScreenOpened(isRevoke: Bool) {}
    func logSwapButtonPermissionApprove(policy: BSDKApprovePolicy) {}
    func logApproveTransactionSent(policy: BSDKApprovePolicy, signerType: String, currentProviderHost: String) {}
}
