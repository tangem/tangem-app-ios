//
//  TangemTabsShowcase.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

#if INTERNAL || DEBUG
import SwiftUI
import TangemUI

struct TangemTabsShowcase: View {
    @State private var tabCount = 5
    @State private var selectedItem = Item.all[0]

    var body: some View {
        DSShowcase("TangemTabs") { controls in
            controls.value("Tabs", $tabCount, in: 1 ... Item.all.count)
            controls.readout("Selected", selection.wrappedValue.text)
        } stage: {
            ScrollView(.horizontal, showsIndicators: false) {
                TangemTabs(data: items, selection: selection)
            }
        }
    }

    private var items: [Item] {
        Array(Item.all.prefix(tabCount))
    }

    private var selection: Binding<Item> {
        Binding(
            get: { items.contains(selectedItem) ? selectedItem : items[0] },
            set: { selectedItem = $0 }
        )
    }
}

private extension TangemTabsShowcase {
    struct Item: TangemTabsTextProvider {
        let text: String

        var id: String { text }

        static var all: [Item] {
            ["Tokens", "Collectibles", "Staking", "Earn", "Activity", "Referral rewards", "Pending transactions"].map { Item(text: $0) }
        }
    }
}
#endif
