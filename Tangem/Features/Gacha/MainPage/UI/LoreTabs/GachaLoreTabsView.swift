//
//  GachaLoreTabsView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUI

struct GachaLoreTabsView: View {
    @ObservedObject var viewModel: GachaLoreTabsViewModel

    var body: some View {
        content.task(viewModel.load)
    }
}

private extension GachaLoreTabsView {
    // MARK: - View properties

    @ViewBuilder
    var content: some View {
        switch viewModel.state {
        case .idle, .loading:
            TabNavigation(data: Constants.placeholderTabs, selection: .constant(GachaLoreTabsMapper.allTab))
                .variant(.material)
                .scrollable()
                .loading(true)
        case .content(let tabs):
            TabNavigation(data: tabs, selection: $viewModel.selectedTab)
                .variant(.material)
                .scrollable()
        case .empty, .failed:
            EmptyView()
        }
    }
}

// MARK: - Constants

private extension GachaLoreTabsView {
    enum Constants {
        static let placeholderTabs: [LoreTab] = [
            LoreTab(kind: .all, title: "", counter: nil),
            LoreTab(kind: .lore("placeholder"), title: "", counter: nil),
        ]
    }
}

// MARK: - Previews

#Preview {
    ZStack {
        DesignSystem.Color.bgPrimary.ignoresSafeArea()

        GachaLoreTabsView(viewModel: GachaLoreTabsViewModel(provider: GachaLoresMockProvider()))
    }
}
