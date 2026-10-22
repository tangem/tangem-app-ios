//
//  CollectiblesPackRevealView+Prize.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemUI

extension CollectiblesPackRevealView {
    struct Prize {
        let imageURL: URL?
        let backImageURL: URL?
        let rarityTitle: String?
        let badgeAppearance: BadgeAppearance
        let glow: GlowRingAppearance?
        let name: String
        let number: String
        let subtitle: String
        let keepTitle: String
    }
}

// [REDACTED_TODO_COMMENT]
extension CollectiblesPackRevealView.Prize {
    init(wonCard: CollectiblesWonCard) {
        let rarity = wonCard.rarity

        self.init(
            imageURL: wonCard.imageFrontURL,
            backImageURL: wonCard.imageBackURL,
            rarityTitle: rarity.map { "\($0.rawValue.capitalized) pull" },
            badgeAppearance: rarity.map(Self.badgeAppearance(of:)) ?? .neutral,
            glow: rarity.flatMap(Self.glow(of:)),
            name: [wonCard.year, wonCard.set].compactMap { $0 }.joined(separator: " "),
            number: wonCard.serialNumber.map { "#\($0)" } ?? "",
            subtitle: wonCard.insuredValue.map {
                "Market value \(CollectiblesPriceFormatter.formatWithCents($0)) · Insured"
            } ?? "",
            keepTitle: "Keep card"
        )
    }
}

private extension CollectiblesPackRevealView.Prize {
    static func badgeAppearance(of rarity: CollectiblesMachine.Tier) -> BadgeAppearance {
        switch rarity {
        case .common: .neutral
        case .uncommon: .success
        case .rare, .epic, .legendary: .info
        }
    }

    static func glow(of rarity: CollectiblesMachine.Tier) -> GlowRingAppearance? {
        switch rarity {
        case .common: nil
        case .rare: .info
        case .uncommon: .success
        case .epic, .legendary: .magic
        }
    }
}
