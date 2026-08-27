//
//  GachaMainView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUI
import TangemUIUtils

struct GachaMainView: View {
    @ObservedObject var viewModel: GachaMainViewModel

    let onBack: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            navigationBar

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    GachaAccountView(viewModel: viewModel.accountViewModel)

                    GachaLoreTabsView(viewModel: viewModel.loreTabsViewModel)
                        .padding(.top, Metrics.tabsTopPadding)

                    GachaPacksView(viewModel: viewModel.packsViewModel)
                        .padding(.top, Metrics.gridTopPadding)
                }
            }
        }
        .infinityFrame()
        .background(DesignSystem.Color.bgPrimary.ignoresSafeArea())
    }
}

private extension GachaMainView {
    // MARK: - View properties

    var navigationBar: some View {
        NavigationBar(
            settings: .init(
                backgroundColor: .clear,
                horizontalPadding: Metrics.horizontalPadding,
                height: Metrics.navBarHeight
            ),
            titleView: { titleView },
            leftButtons: { NavigationBarButton.back(action: onBack) },
            rightButtons: { ActionsMenu(onSelect: viewModel.onActionSelected) }
        )
        .padding(.top, Metrics.navBarTopPadding)
        .environment(\.isRedesign, true)
    }

    var titleView: some View {
        // [REDACTED_TODO_COMMENT]
        Text("Gacha").style(DesignSystem.Font.bodyMediumToken, color: DesignSystem.Color.textPrimary)
    }
}

// MARK: - Metrics

private extension GachaMainView {
    enum Metrics {
        static let horizontalPadding: CGFloat = 16
        static let navBarHeight: CGFloat = 56
        static let navBarTopPadding: CGFloat = 8
        static let tabsTopPadding: CGFloat = 40
        static let gridTopPadding: CGFloat = 16
    }
}

// MARK: - Previews

#Preview {
    GachaMainView(viewModel: GachaMainViewModel(), onBack: {})
}
