//
//  TangemPayCampaignService.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import Foundation

struct TangemPayCampaignService {
    @Injected(\.tangemPayCampaignKeyStorage) private var storage: TangemPayCampaignKeyStorage

    /// The whole `deep_link_value` is the campaign key the BFF expects, prefix included. It is carried on to the
    /// backend and back into a link, so it is held to the shape every identifier a link of ours carries has —
    /// whichever way it arrived, the AppsFlyer SDK's callback or a link of ours.
    static func campaignKey(fromDeepLinkValue value: String) -> String? {
        guard value.hasPrefix(Constants.deepLinkValuePrefix),
              value.count > Constants.deepLinkValuePrefix.count else {
            return nil
        }

        return DeeplinkRules.identifier(value)
    }

    var pendingCampaignKey: String? {
        storage.pendingCampaignKey
    }

    var pendingCampaignKeyPublisher: AnyPublisher<String?, Never> {
        storage.pendingCampaignKeyPublisher
    }

    func markPending(campaignKey: String) {
        storage.pendingCampaignKey = campaignKey
    }

    func clearPending() {
        storage.pendingCampaignKey = nil
    }
}

private extension TangemPayCampaignService {
    enum Constants {
        static let deepLinkValuePrefix = "tpay_for_"
    }
}
