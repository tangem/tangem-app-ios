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
}

extension CallToActionMarketingBanner {
    struct PseudoProvider: Hashable {
        let categoryLabel: String?
        let subtitle: String?
        let etaLabel: String?
        let partnerLabel: String?
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
