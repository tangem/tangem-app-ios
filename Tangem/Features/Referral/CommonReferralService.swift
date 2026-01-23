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
        AnalyticsLogger.debug("Start binding for refcode: \(refcode)")
        AppSettings.shared.hasReferralBindingRequest = true

        runTask(in: self, isDetached: true) { service in
            do {
                let request = ReferralDTO.Request(
                    walletIds: service.userWalletRepository.models.map { $0.userWalletId.stringValue },
                    referralCode: refcode,
                    utmCampaign: campaign
                )

                try await service.tangemApiService.bindReferral(request: request)

                AnalyticsLogger.debug("Refcode \(refcode) was binded")

                await MainActor.run {
                    AppSettings.shared.hasReferralBindingRequest = false
                }
            } catch {
                AnalyticsLogger.debug("Refcode \(refcode) was not binded")
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
    var refcode: String? {
        AppSettings.shared.referralRefcode
    }

    var campaign: String? {
        AppSettings.shared.referralCampaign
    }

    var hasNoReferral: Bool {
        if let refcode {
            return refcode.isEmpty
        }

        return true
    }

    func saveReferralIfNeeded(refcode: String, campaign: String?) {
        guard hasNoReferral else {
            return
        }

        saveReferral(refcode: refcode, campaign: campaign)
    }

    func retryBindingIfNeeded() {
        guard AppSettings.shared.hasReferralBindingRequest else {
            return
        }

        retryBinding()
    }

    func saveAndBindIfNeeded(refcode: String, campaign: String?) {
        if AppSettings.shared.hasReferralBindingRequest {
            retryBinding()
            return
        }

        guard hasNoReferral else {
            AnalyticsLogger.debug("Refcode \(refcode) was not saved because referral already exists")
            return
        }

        saveReferral(refcode: refcode, campaign: campaign)
        bind(refcode: refcode, campaign: campaign)
    }
}
