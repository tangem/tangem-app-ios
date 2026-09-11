//
//  GachaLoreTabsView+LoreTab.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import TangemUI

extension GachaLoreTabsView {
    struct LoreTab: TabNavigationItem {
        enum Kind: Hashable {
            case all
            case lore(String)

            var loreID: String? {
                switch self {
                case .all:
                    return nil
                case .lore(let id):
                    return id
                }
            }
        }

        let kind: Kind
        let title: String
        let counter: String?

        var id: Kind { kind }
    }
}
