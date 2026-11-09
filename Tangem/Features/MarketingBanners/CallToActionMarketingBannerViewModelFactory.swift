//
//  CallToActionMarketingBannerViewModelFactory.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

enum CallToActionMarketingBannerViewModelFactory {
    static func make(
        from banner: MarketingBanner,
        incomingActionParser: IncomingActionParser = IncomingActionParser()
    ) -> CallToActionMarketingBanner? {
        guard case .deeplink(let url) = banner.action,
              CallToActionMarketingBannerLinkRoute(link: url, incomingActionParser: incomingActionParser) != nil else {
            return nil
        }

        switch banner.placement {
        case .pseudoProvider(let content):
            return .pseudoProvider(CallToActionMarketingBannerViewModel(
                id: banner.id,
                title: banner.text,
                buttonTitle: content.buttonText,
                isGlowing: content.isGlowing,
                link: url,
                isDismissible: banner.isDismissible,
                content: .init(
                    categoryLabel: content.categoryLabel,
                    subtitle: content.subtitle,
                    etaLabel: content.etaLabel,
                    partnerLabel: content.partnerLabel
                )
            ))

        case .standaloneCTA(let content):
            return .standalone(CallToActionMarketingBannerViewModel(
                id: banner.id,
                title: banner.text,
                buttonTitle: content.buttonText,
                isGlowing: content.isGlowing,
                link: url,
                isDismissible: banner.isDismissible,
                content: .init(subtitle: content.subtitle, iconURL: banner.iconURL)
            ))

        case .standalone, .linkedToProvider:
            return nil
        }
    }
}
