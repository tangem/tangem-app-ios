//
//  MoneyAccountBannerButtonTitle.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemLocalization

enum MoneyAccountBannerButtonTitle {
    static func applying(
        to banners: [CallToActionMarketingBanner],
        moneyAccountState: TangemPayMoneyAccountState?
    ) -> [CallToActionMarketingBanner] {
        guard let title = title(for: moneyAccountState) else {
            return banners
        }

        return banners.map { banner in
            guard case .pseudoProvider(let viewModel) = banner, isMoneyAccountLink(viewModel.link) else {
                return banner
            }

            return .pseudoProvider(CallToActionMarketingBannerViewModel(
                id: viewModel.id,
                title: viewModel.title,
                buttonTitle: title,
                isGlowing: viewModel.isGlowing,
                link: viewModel.link,
                isDismissible: viewModel.isDismissible,
                content: viewModel.content
            ))
        }
    }

    static func title(for moneyAccountState: TangemPayMoneyAccountState?) -> String? {
        switch moneyAccountState {
        case .active, .activating:
            Localization.commonContinue
        case .notStarted, .activationFailed, .deactivated:
            Localization.commonActivate
        case .loading, .syncNeeded, .unavailable, .none:
            nil
        }
    }

    static func isMoneyAccountLink(_ link: URL) -> Bool {
        guard let deeplink = DeeplinkURL(url: link), case .onboardVirtualAccount = DeeplinkNavigationAction(link: deeplink) else {
            return false
        }

        return true
    }
}
