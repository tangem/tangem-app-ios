//
//  TangemPayCampaignHotWalletCreator.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import struct TangemUIUtils.AlertBinder

struct TangemPayCampaignHotWalletCreator {
    @Injected(\.userWalletRepository)
    private var userWalletRepository: UserWalletRepository

    private let mobileWalletFeatureProvider = MobileWalletFeatureProvider()

    var restrictionAlert: AlertBinder? {
        mobileWalletFeatureProvider.isAvailable ? nil : mobileWalletFeatureProvider.makeRestrictionAlert()
    }

    func createWallet() async throws -> UserWalletModel {
        let userWalletModel = try await MobileCreationUtil().makeCreatedModel()

        AmplitudeWrapper.shared.setUserIdIfOnboarding(userWalletId: userWalletModel.userWalletId)
        logWalletCreatedAnalytics()

        BackendAuthenticationRegistrar.registerNewMobileWallet(userWalletModel)
        try userWalletRepository.add(userWalletModel: userWalletModel)

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
