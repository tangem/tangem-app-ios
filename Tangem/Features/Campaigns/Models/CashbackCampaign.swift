//
//  CashbackCampaign.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Kingfisher
import TangemLocalization
import TangemFoundation

enum CashbackCampaign: String, CaseIterable {
    case whaleSwap = "whale-swap-cashback"
    case reactivation = "reactivation-cashback"

    var displayName: String {
        switch self {
        case .whaleSwap: "Whale Swap Cashback"
        case .reactivation: "Reactivation Cashback"
        }
    }

    var summaryDescription: String {
        switch self {
        case .whaleSwap: Localization.promoCampaignWhaleSwapSummaryDescription
        case .reactivation: Localization.promoCampaignReactivationSummaryDescription
        }
    }

    var termsURL: URL? {
        switch self {
        case .whaleSwap: URL(string: "https://tangem.com/docs/en/whale-swap-cashback-terms.pdf")
        case .reactivation: URL(string: "https://tangem.com/docs/en/summer-swap-cashback-terms.pdf")
        }
    }

    var blogPost: TangemBlogUrlBuilder.Post {
        switch self {
        case .whaleSwap: .whaleSwapCashback
        case .reactivation: .reactivationCashback
        }
    }
}

// MARK: - Promo image

extension CashbackCampaign {
    var promoImageURL: URL {
        AppEnvironment.current.iconBaseUrl.appendingPathComponent("stories/\(promoImageFileName)")
    }

    static func prefetchPromoImages() {
        ImagePrefetcher(urls: allCases.map(\.promoImageURL), options: [.cacheOriginalImage]).start()
    }

    private var promoImageFileName: String {
        switch self {
        case .whaleSwap: "Whale_Swap_Cashback.webp"
        case .reactivation: "Reactivation_Cashback.webp"
        }
    }
}
