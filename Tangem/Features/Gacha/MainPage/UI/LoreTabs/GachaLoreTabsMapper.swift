//
//  GachaLoreTabsMapper.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

enum GachaLoreTabsMapper {
    static let allTab = GachaLoreTabsView.LoreTab(kind: .all, title: Constants.allTabTitle, counter: nil)

    static func map(_ lores: [GachaLore]) -> [GachaLoreTabsView.LoreTab] {
        guard !lores.isEmpty else {
            return []
        }

        let totalPacksCount = lores.sum(by: \.packsCount)

        let allTab = GachaLoreTabsView.LoreTab(
            kind: .all,
            title: Constants.allTabTitle,
            counter: "\(totalPacksCount)"
        )

        let loreTabs = lores.map { lore in
            GachaLoreTabsView.LoreTab(
                kind: .lore(lore.id),
                title: lore.title,
                counter: "\(lore.packsCount)"
            )
        }

        return [allTab] + loreTabs
    }
}

private extension GachaLoreTabsMapper {
    enum Constants {
        // [REDACTED_TODO_COMMENT]
        static let allTabTitle = "All cards"
    }
}
