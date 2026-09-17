//
//  CommonReferralService.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//
import TangemFoundation

final class CommonReferralService {
    @Injected(\.tangemApiService) private var tangemApiService: TangemApiService
    @Injected(\.userWalletRepository) private var userWalletRepository: UserWalletRepository

    func saveReferral(refcode: String, campaign: String?) {
        AppSettings.shared.referralRefcode = refcode
        AppSettings.shared.referralCampaign = campaign
    }

    private func bind(refcode: String, campaign: String?) {
        AppSettings.shared.hasReferralBindingRequest = true

        let walletIds = userWalletRepository.models.map { $0.userWalletId.stringValue }

        // A referral that arrives before there is a wallet stays owed: a wallet created from here carries it in
        // its creation request (`WalletCreationContextBuilder.enrichReferral`), a wallet that already exists
        // is bound to it when the wallets are known — on the promo screen or on the next launch.
        guard !walletIds.isEmpty else {
            AnalyticsLogger.info("Refcode \(refcode) is owed a binding once there is a wallet")
            return
        }

        AnalyticsLogger.info("Start binding for refcode: \(refcode)")

        runTask(in: self, isDetached: true) { service in
            do {
                let request = ReferralDTO.Request(
                    walletIds: walletIds,
                    referralCode: refcode,
                    utmCampaign: campaign
                )

                try await service.tangemApiService.bindReferral(request: request)

                AnalyticsLogger.info("Refcode \(refcode) was binded")

                await MainActor.run {
                    AppSettings.shared.hasReferralBindingRequest = false
                }
            } catch {
                AnalyticsLogger.error(error: "Refcode \(refcode) was not binded")
                AppLogger.error(error: error)
            }
        }
    }

    private func retryBinding() {
        guard let refcode else {
            return
        }

        bind(refcode: refcode, campaign: campaign)
    }
}

extension CommonReferralService: ReferralService {
    /// Normalized on read: builds before the AppsFlyer parameter validation could persist a blank or a
    /// literal `"null"` refcode, which would otherwise pass as an existing referral and block every new one.
    var refcode: String? {
        ReferralParam.normalized(AppSettings.shared.referralRefcode)
    }

    var campaign: String? {
        ReferralParam.normalized(AppSettings.shared.referralCampaign)
    }

    var hasNoReferral: Bool {
        refcode == nil
    }

    func retryBindingIfNeeded() {
        guard AppSettings.shared.hasReferralBindingRequest else {
            return
        }

        retryBinding()
    }

    func saveAndBindIfNeeded(refcode: String, campaign: String?) {
        // A binding is owed for a referral that was stored, and normalization leaves a blank or a `"null"`
        // one from an older build as no referral at all — there is nothing to retry, and the arriving
        // refcode would be dropped on the way out.
        if AppSettings.shared.hasReferralBindingRequest, !hasNoReferral {
            retryBinding()
            return
        }

        guard hasNoReferral else {
            AnalyticsLogger.warning("Refcode \(refcode) was not saved because referral already exists")
            return
        }

        saveReferral(refcode: refcode, campaign: campaign)
        bind(refcode: refcode, campaign: campaign)
    }
}
