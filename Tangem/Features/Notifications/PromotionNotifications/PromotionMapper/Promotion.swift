//
//  Promotion.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

struct Promotion: Hashable {
    let id: Int
    let placeholder: PromotionPlacement
    let priority: String?
    let title: String
    let subtitle: String
    let iconUrl: URL?
    let deeplink: URL?
    let buttonEnabled: Bool
    let buttonText: String?
    let dismissable: Bool
    let campaignId: Int?
    let campaignName: String?
}

extension Promotion {
    func withCampaignName(_ campaignName: String?) -> Promotion {
        Promotion(
            id: id,
            placeholder: placeholder,
            priority: priority,
            title: title,
            subtitle: subtitle,
            iconUrl: iconUrl,
            deeplink: deeplink,
            buttonEnabled: buttonEnabled,
            buttonText: buttonText,
            dismissable: dismissable,
            campaignId: campaignId,
            campaignName: campaignName
        )
    }
}
