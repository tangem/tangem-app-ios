//
//  WelcomeV2AnalyticsProvider.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

/// One button — one event: every tappable element gets its own event instead of a shared
/// event with a path property, so funnels build without filters.
protocol WelcomeV2AnalyticsProvider {
    func logIntroductionProcessScreenOpened(entryReason: Analytics.ParameterValue)
    func logWelcomeMediaError(stage: Analytics.ParameterValue)
    func logLegalOpened(document: Analytics.ParameterValue)

    func logCreateWalletButton()
    func logIHaveWalletButton()
    func logCreateWalletIntroScreenOpened()
    func logSheetDismissed(sheet: Analytics.ParameterValue, reason: Analytics.ParameterValue)

    func logHardwareWalletButton()
    func logMobileWalletButton()
    func logSignInWithCardButton()
    func logImportExistingWalletButton()
    func logImportWalletRequest(hasCloudBackup: Bool)

    func logButtonScanCard()
    func logCardWasScanned(contextParams: Analytics.ContextParams)
    func logScanCancelled()
    func logScanError(_ error: Error)
    func logScanTroubleshooting()
    func logTroubleshootingTryAgain()
    func logTroubleshootingReadMore()
    func logTroubleshootingRequestSupport()
    func logCardSignIn(userWalletModel: UserWalletModel)

    func logButtonBuy()
    func logButtonBuyTangem()
    func logShopScreenOpened()
}

// MARK: - Dependencies

private struct WelcomeV2AnalyticsProviderKey: InjectionKey {
    static var currentValue: WelcomeV2AnalyticsProvider = CommonWelcomeV2AnalyticsService()
}

extension InjectedValues {
    var welcomeV2AnalyticsProvider: WelcomeV2AnalyticsProvider {
        get { Self[WelcomeV2AnalyticsProviderKey.self] }
        set { Self[WelcomeV2AnalyticsProviderKey.self] = newValue }
    }
}
