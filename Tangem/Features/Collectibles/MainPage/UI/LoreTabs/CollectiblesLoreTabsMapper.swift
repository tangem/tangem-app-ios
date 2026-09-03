//
//  CollectiblesLoreTabsMapper.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

enum CollectiblesLoreTabsMapper {
    static let allTab = CollectiblesLoreTabsView.LoreTab(kind: .all, title: Constants.allTabTitle, counter: nil)

    static func map(_ lores: [CollectiblesLore]) -> [CollectiblesLoreTabsView.LoreTab] {
        guard !lores.isEmpty else {
            return []
        }

        let totalPacksCount = lores.sum(by: \.packsCount)

        let allTab = CollectiblesLoreTabsView.LoreTab(
            kind: .all,
            title: Constants.allTabTitle,
            counter: "\(totalPacksCount)"
        )

        let loreTabs = lores.map { lore in
            CollectiblesLoreTabsView.LoreTab(
                kind: .lore(lore.id),
                title: lore.title,
                counter: "\(lore.packsCount)"
            )
        }

        return [allTab] + loreTabs
    }
}

private extension CollectiblesLoreTabsMapper {
    enum Constants {
        // [REDACTED_TODO_COMMENT]
        static let allTabTitle = "All cards"
    }
}
