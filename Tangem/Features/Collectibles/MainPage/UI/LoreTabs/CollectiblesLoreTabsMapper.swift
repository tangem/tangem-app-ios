//
//  CollectiblesLoreTabsMapper.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemLocalization

enum CollectiblesLoreTabsMapper {
    static let allTab = CollectiblesLoreTabsView.LoreTab(kind: .all, title: Constants.allTabTitle, counter: nil)

    static func map(_ catalogue: CollectiblesLoreCatalogue) -> [CollectiblesLoreTabsView.LoreTab] {
        guard !catalogue.lores.isEmpty else {
            return []
        }

        let allTab = CollectiblesLoreTabsView.LoreTab(
            kind: .all,
            title: Constants.allTabTitle,
            counter: "\(catalogue.totalPacksCount)"
        )

        let loreTabs = catalogue.lores.map { lore in
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
        static let allTabTitle = Localization.collectiblesMainAllPacksTab
    }
}
