//
//  TangemPayCampaignHotWalletCreator.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation
import struct TangemUIUtils.AlertBinder

struct TangemPayCampaignHotWalletCreator {
    @Injected(\.pushNotificationsInteractor)
    private var pushNotificationsInteractor: PushNotificationsInteractor

    private let mobileWalletFeatureProvider = MobileWalletFeatureProvider()

    var restrictionAlert: AlertBinder? {
        guard mobileWalletFeatureProvider.isAvailable else {
            return mobileWalletFeatureProvider.makeRestrictionAlert()
        }

        guard FeatureProvider.isAvailable(.mobileWalletMultiCreation) else {
            return nil
        }

        return MobileWalletLimitUtil().restriction(for: .create)?.makeAlert()
    }

    func createWallet() async throws -> UserWalletModel {
        let creationUtil = MobileCreationUtil()
        let userWalletModel = try await creationUtil.makeCreatedModel()

        AmplitudeWrapper.shared.setUserIdIfOnboarding(userWalletId: userWalletModel.userWalletId)
        logWalletCreatedAnalytics()

        try creationUtil.store(userWalletModel)

        await runOnMain { pushNotificationsInteractor.suppressAfterLoginRequestsInCurrentSession() }

        return userWalletModel
    }

    private func logWalletCreatedAnalytics() {
        var params: [Analytics.ParameterKey: String] = [
            .creationType: Analytics.ParameterValue.walletCreationTypeNewSeed.rawValue,
            .seedLength: "12",
            .passphrase: Analytics.ParameterValue.empty.rawValue,
            .source: MobileCreateWalletSource.createWalletIntro.analyticsParameterValue.rawValue,
        ]

        params.enrich(with: ReferralAnalyticsHelper().getReferralParams())

        Analytics.log(
            event: .walletCreatedSuccessfully,
            params: params,
            analyticsSystems: .all,
            contextParams: .custom(.mobileWallet)
        )
    }
}
