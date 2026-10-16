//
//  MobileSocialLoginAnalyticsLogger.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

struct MobileSocialLoginAnalyticsLogger {
    func logContinueWithAppleButton(source: MobileSocialLoginSource) {
        Analytics.log(
            .socialLoginButtonContinueWithApple,
            params: [.source: source.analyticsParameterValue],
            contextParams: contextParams
        )
    }

    func logMinOSNotSupportedNotice() {
        Analytics.log(.socialLoginNoticeMinOSNotSupported, contextParams: contextParams)
    }

    func logRiskConsentScreenOpened() {
        Analytics.log(.socialLoginRiskConsentScreenOpened, contextParams: contextParams)
    }

    func logRiskConsentNotConfirmedError() {
        Analytics.log(.socialLoginErrorRiskConsentNotConfirmed, contextParams: contextParams)
    }

    func logMarketingEmailsConsent(_ consent: MobileSocialMarketingConsent) {
        Analytics.log(
            event: .socialLoginConsentMarketingEmails,
            params: [
                .consentType: Analytics.ParameterValue.consentTypeMarketingEmails.rawValue,
                .consentGiven: Analytics.ParameterValue.affirmativeOrNegative(for: consent.isGiven).rawValue,
                .consentText: consent.consentText,
            ],
            contextParams: contextParams
        )
    }

    func logErrorShown(message: String) {
        Analytics.log(
            event: .socialLoginErrorShown,
            params: [.errorMessage: message],
            contextParams: contextParams
        )
    }

    func logWalletCreated(source: MobileSocialLoginSource) {
        logWalletCreatedSuccessfully(creationType: .walletCreationTypeNewSocialLogin, source: source)
    }

    func logWalletRestored(source: MobileSocialLoginSource) {
        logWalletCreatedSuccessfully(creationType: .walletCreationTypeSocialLoginImport, source: source)
    }
}

// MARK: - Private methods

private extension MobileSocialLoginAnalyticsLogger {
    var contextParams: Analytics.ContextParams {
        .custom(.mobileWallet)
    }

    func logWalletCreatedSuccessfully(creationType: Analytics.ParameterValue, source: MobileSocialLoginSource) {
        var params: [Analytics.ParameterKey: String] = [
            .creationType: creationType.rawValue,
            .seedLength: Constants.seedPhraseLength,
            .passphrase: Analytics.ParameterValue.empty.rawValue,
            .source: source.analyticsParameterValue.rawValue,
        ]

        params.enrich(with: ReferralAnalyticsHelper().getReferralParams())

        Analytics.log(
            event: .walletCreatedSuccessfully,
            params: params,
            analyticsSystems: .all,
            contextParams: contextParams
        )
    }
}

// MARK: - Constants

private extension MobileSocialLoginAnalyticsLogger {
    enum Constants {
        static let seedPhraseLength = "12"
    }
}
