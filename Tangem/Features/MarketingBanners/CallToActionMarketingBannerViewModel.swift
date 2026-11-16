//
//  CallToActionMarketingBannerViewModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

enum CallToActionMarketingBanner: Identifiable, Hashable {
    case pseudoProvider(CallToActionMarketingBannerViewModel<PseudoProvider>)
    case standalone(CallToActionMarketingBannerViewModel<Standalone>)

    var id: Int {
        switch self {
        case .pseudoProvider(let viewModel):
            viewModel.id
        case .standalone(let viewModel):
            viewModel.id
        }
    }

    var link: URL {
        switch self {
        case .pseudoProvider(let viewModel):
            viewModel.link
        case .standalone(let viewModel):
            viewModel.link
        }
    }

    var replacedSlot: MarketingBanner.RecommendedSlot? {
        switch self {
        case .pseudoProvider(let viewModel):
            viewModel.content.replacedSlot
        case .standalone:
            nil
        }
    }
}

extension CallToActionMarketingBanner {
    struct PseudoProvider: Hashable {
        let categoryLabel: String?
        let subtitle: String?
        let etaLabel: String?
        let partnerLabel: String?
        let replacedSlot: MarketingBanner.RecommendedSlot?
    }

    struct Standalone: Hashable {
        let subtitle: String?
        let iconURL: URL?
    }
}

enum CallToActionMarketingBannerAction: Equatable {
    case open(URL)
    case dismiss(campaignId: Int)
}

struct CallToActionMarketingBannerViewModel<Content: Hashable>: Identifiable, Hashable {
    let id: Int
    let title: String
    let buttonTitle: String
    let isGlowing: Bool
    let link: URL
    let isDismissible: Bool
    let content: Content
}
