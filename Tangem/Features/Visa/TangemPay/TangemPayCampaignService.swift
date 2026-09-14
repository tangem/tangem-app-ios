//
//  TangemPayCampaignService.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

struct TangemPayCampaignService {
    /// The whole `deep_link_value` is the campaign key the BFF expects, prefix included.
    static func campaignKey(fromDeepLinkValue value: String) -> String? {
        guard FeatureProvider.isAvailable(.tangemPayCustomCards),
              value.hasPrefix(Constants.deepLinkValuePrefix),
              value.count > Constants.deepLinkValuePrefix.count else {
            return nil
        }

        return value
    }

    var pendingCampaignKey: String? {
        AppSettings.shared.pendingTangemPayCampaignKey
    }

    func markPending(campaignKey: String) {
        AppSettings.shared.pendingTangemPayCampaignKey = campaignKey
    }

    func clearPending() {
        AppSettings.shared.pendingTangemPayCampaignKey = nil
    }
}

private extension TangemPayCampaignService {
    enum Constants {
        static let deepLinkValuePrefix = "tpay_for_"
    }
}
