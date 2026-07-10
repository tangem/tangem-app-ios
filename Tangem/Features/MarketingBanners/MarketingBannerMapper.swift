//
//  MarketingBannerMapper.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

enum MarketingBannerMapper {
    static func banners(from campaigns: [MarketingCampaignsDTO.Campaign]) -> MarketingBanners {
        let banners = campaigns
            .sorted { $0.priority < $1.priority }
            .compactMap { makeBanner(from: $0) }

        return MarketingBanners(
            standalone: banners.filter { $0.isStandalone },
            linked: banners.filter { !$0.isStandalone }
        )
    }

    static func makeBanner(from campaign: MarketingCampaignsDTO.Campaign) -> MarketingBanner? {
        guard let text = campaign.banner.text else {
            return nil
        }

        let placement: MarketingBanner.Placement = switch campaign.banner.uiType {
        case .linkedToProvider:
            .linkedToProvider(providerIds: campaign.providerIds ?? [])
        case .standalone, .unknown:
            .standalone
        }

        return MarketingBanner(
            id: campaign.id,
            text: text,
            iconURL: campaign.banner.icon,
            backgroundColorHex: campaign.banner.bgColor,
            placement: placement,
            action: campaign.banner.deeplink.map(MarketingBanner.Action.deeplink),
            isDismissible: campaign.banner.dismissible
        )
    }
}
