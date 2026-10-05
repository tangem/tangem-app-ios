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
        let gradeText: String
        let serialText: String
        let rarityTitle: String
        let badgeAppearance: BadgeAppearance
        let glow: GlowRingAppearance
        let name: String
        let number: String
        let subtitle: String
        let keepTitle: String
        let sellBackTitle: String
    }
}

// [REDACTED_TODO_COMMENT]
extension CollectiblesPackRevealView.Prize {
    static let sample = CollectiblesPackRevealView.Prize(
        imageURL: URL(string: "https://d1xpxki1g4htqu.cloudfront.net/LkmgD1iqL7MVEb9zEUiTe96bFy4ndWn2VA5d7Hlypuw"),
        gradeText: "PSA • GEM-MT 10",
        serialText: "#00000000",
        rarityTitle: "Uncommon pull",
        badgeAppearance: .success,
        glow: .success,
        name: "2024 Series One",
        number: "#216",
        subtitle: "Market value $62.00 · Insured",
        keepTitle: "Keep card",
        sellBackTitle: "Sell back for $55.80"
    )
}
