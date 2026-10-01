//
//  CommonWelcomeV2AnalyticsService.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

final class CommonWelcomeV2AnalyticsService: WelcomeV2AnalyticsProvider {
    private let signInAnalyticsLogger = SignInAnalyticsLogger()

    func logIntroductionProcessScreenOpened(entryReason: Analytics.ParameterValue) {
        Analytics.log(.introductionProcessOpened, params: [.entryReason: entryReason])
    }

    func logWelcomeMediaError(stage: Analytics.ParameterValue) {
        Analytics.log(.introductionProcessWelcomeMediaError, params: [.stage: stage])
    }

    func logLegalOpened(document: Analytics.ParameterValue) {
        Analytics.log(.introductionProcessLegalOpened, params: [.document: document])
    }

    func logCreateWalletButton() {
        Analytics.log(.introductionProcessButtonCreateNewWallet)
    }

    func logIHaveWalletButton() {
        Analytics.log(.introductionProcessButtonIHaveWallet)
    }

    func logCreateWalletIntroScreenOpened() {
        Analytics.log(
            event: .introductionProcessCreateWalletIntroScreenOpened,
            params: ReferralAnalyticsHelper().getReferralParams()
        )
    }

    func logSheetDismissed(sheet: Analytics.ParameterValue, reason: Analytics.ParameterValue) {
        Analytics.log(
            .introductionProcessSheetDismissed,
            params: [.sheet: sheet, .dismissReason: reason]
        )
    }

    func logHardwareWalletButton() {
        Analytics.log(.introductionProcessButtonHardwareWallet)
    }

    func logMobileWalletButton() {
        Analytics.log(.buttonMobileWallet, params: [.source: .createWalletIntro])
    }

    func logSignInWithCardButton() {
        Analytics.log(.introductionProcessButtonSignInWithCard)
    }

    func logImportExistingWalletButton() {
        Analytics.log(
            event: .introductionProcessButtonImportExistingWallet,
            params: [.productType: Analytics.ProductType.mobileWallet.rawValue],
            contextParams: .empty
        )
    }

    func logImportWalletRequest(hasCloudBackup: Bool) {
        Analytics.log(
            .importWalletRequest,
            params: [.backupCloud: hasCloudBackup ? .available : .unavailable],
            contextParams: .custom(.mobileWallet)
        )
    }

    func logButtonScanCard() {
        Analytics.log(
            Analytics.CardScanSource.welcome.cardScanButtonEvent,
            params: [.source: Analytics.CardScanSource.welcome.cardWasScannedParameterValue]
        )
    }

    func logCardWasScanned(contextParams: Analytics.ContextParams) {
        Analytics.log(
            .cardWasScanned,
            params: [.source: Analytics.CardScanSource.welcome.cardWasScannedParameterValue],
            contextParams: contextParams
        )
    }

    func logScanCancelled() {
        Analytics.log(.introductionProcessScanCancelled, params: [.source: .introduction])
    }

    func logScanError(_ error: Error) {
        Analytics.logScanError(error, source: .introduction)
        Analytics.logVisaCardScanErrorIfNeeded(error, source: .introduction)
    }

    func logScanTroubleshooting() {
        Analytics.log(.cantScanTheCard, params: [.source: .introduction])
    }

    func logTroubleshootingTryAgain() {
        Analytics.log(.cantScanTheCardTryAgainButton, params: [.source: .introduction])
    }

    func logTroubleshootingReadMore() {
        Analytics.log(.cantScanTheCardButtonBlog, params: [.source: .introduction])
    }

    func logTroubleshootingRequestSupport() {
        Analytics.log(.requestSupport, params: [.source: .introduction])
    }

    func logCardSignIn(userWalletModel: UserWalletModel) {
        signInAnalyticsLogger.logSignInEvent(signInType: .card, userWalletModel: userWalletModel)
    }

    func logButtonBuy() {
        Analytics.log(.basicButtonBuy, params: [.source: .stories])
    }

    func logShopScreenOpened() {
        Analytics.log(.shopScreenOpened)
    }
}
