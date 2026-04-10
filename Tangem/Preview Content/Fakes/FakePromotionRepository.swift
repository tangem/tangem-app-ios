//
//  FakePromotionRepository.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine

class FakePromotionRepository: PromotionRepository {
    private let promotions: [PromotionPlacement: [Promotion]]

    init(promotions: [PromotionPlacement: [Promotion]] = [
        .main: [
            PromotionsDTO.Load.Item(
                id: 1,
                placeholder: .main,
                priority: "high",
                title: "Buy Bitcoin with 0% fee",
                subtitle: "Limited time offer for Tangem users",
                iconUrl: IconURLBuilder().tokenIconURL(id: "bitcoin"),
                deeplink: URL(string: "tangem://buy?currency=BTC"),
                buttonEnabled: true,
                buttonText: "Buy Now",
                dismissable: true
            ),
            PromotionsDTO.Load.Item(
                id: 2,
                placeholder: .main,
                priority: "medium",
                title: "Stake ETH and earn rewards",
                subtitle: "Up to 5% APY on Ethereum staking",
                iconUrl: IconURLBuilder().tokenIconURL(id: "ethereum"),
                deeplink: URL(string: "tangem://staking?currency=ETH"),
                buttonEnabled: true,
                buttonText: "Stake Now",
                dismissable: true
            ),
        ],
        .news: [
            PromotionsDTO.Load.Item(
                id: 3,
                placeholder: .news,
                priority: "low",
                title: "New tokens available",
                subtitle: "Check out the latest additions to our token list",
                iconUrl: IconURLBuilder().tokenIconURL(id: "solana"),
                deeplink: nil,
                buttonEnabled: false,
                buttonText: nil,
                dismissable: false
            ),
        ],
    ]) {
        self.promotions = promotions
    }

    func promotionsPublisher(placeholder: PromotionPlacement) -> AnyPublisher<[Promotion], Never> {
        Just(promotions[placeholder, default: []]).eraseToAnyPublisher()
    }

    func loadPromotions() async {}

    func hidePromotion(displayId: Int) async throws {}
}
