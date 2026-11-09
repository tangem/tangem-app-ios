//
//  MarketingBannerMapper.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

enum MarketingBannerMapper {
    static func banners(
        from campaigns: [MarketingCampaignsDTO.Campaign],
        now: Date = .now
    ) -> MarketingBanners {
        let banners = campaigns
            .filter { isActive($0, now: now) }
            .sorted { $0.priority < $1.priority }
            .compactMap { makeBanner(from: $0) }

        return MarketingBanners(
            standalone: banners.filter { $0.isStandalone },
            linked: banners.filter { $0.isLinkedToProvider },
            callToAction: banners.filter { $0.isCallToAction }
        )
    }

    private static func isActive(_ campaign: MarketingCampaignsDTO.Campaign, now: Date) -> Bool {
        if let startAt = campaign.startAt, now < startAt {
            return false
        }

        if let endAt = campaign.endAt, now > endAt {
            return false
        }

        return true
    }

    static func makeBanner(from campaign: MarketingCampaignsDTO.Campaign) -> MarketingBanner? {
        guard let text = campaign.banner.text, let placement = makePlacement(from: campaign) else {
            return nil
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

    private static func makePlacement(from campaign: MarketingCampaignsDTO.Campaign) -> MarketingBanner.Placement? {
        let banner = campaign.banner

        switch banner.uiType {
        case .standalone:
            return .standalone

        case .linkedToProvider:
            return .linkedToProvider(providerIds: campaign.providerIds ?? [])

        case .pseudoProvider:
            guard banner.text?.nilIfEmpty != nil, let buttonText = banner.buttonText?.nilIfEmpty else {
                return nil
            }

            return .pseudoProvider(MarketingBanner.PseudoProvider(
                categoryLabel: banner.categoryLabel?.nilIfEmpty,
                subtitle: banner.subtitle?.nilIfEmpty,
                etaLabel: banner.etaLabel?.nilIfEmpty,
                partnerLabel: banner.partnerLabel?.nilIfEmpty,
                buttonText: buttonText,
                isGlowing: banner.glow ?? false
            ))

        case .standaloneCTA:
            guard banner.text?.nilIfEmpty != nil, let buttonText = banner.buttonText?.nilIfEmpty else {
                return nil
            }

            return .standaloneCTA(MarketingBanner.StandaloneCTA(
                subtitle: banner.subtitle?.nilIfEmpty,
                buttonText: buttonText,
                isGlowing: banner.glow ?? false
            ))

        case .unknown:
            return nil
        }
    }
}
