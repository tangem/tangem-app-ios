//
//  TangemPayMainViewModel+CardDeliveryBanner.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import TangemLocalization

extension TangemPayMainViewModel {
    enum CardDeliveryBannerState {
        case single(activatableCard: TangemPayCard?)
        case multiple

        var title: String {
            switch self {
            case .single: Localization.tangempayCardDeliveryBannerTitle
            case .multiple: Localization.tangempayCardDeliveryBannerTitleMany
            }
        }

        var description: String {
            switch self {
            case .single: Localization.tangempayCardDeliveryBannerDescription
            case .multiple: Localization.tangempayCardDeliveryBannerDescriptionMany
            }
        }

        var activatableCard: TangemPayCard? {
            switch self {
            case .single(let card): card
            case .multiple: nil
            }
        }
    }
}
