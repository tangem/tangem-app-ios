//
//  PolymarketCategoryView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemPolymarketUI
import TangemUI
import TangemUIUtils

struct PolymarketCategoryView: View {
    @ObservedObject var viewModel: PolymarketCategoryViewModel

    @State private var headerHeight: CGFloat = 0

    var body: some View {
        ZStack(alignment: .top) {
            content

            header
        }
        .background(DesignSystem.Color.bgPrimary.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
    }

    private var header: some View {
        VStack(spacing: 0) {
            PolymarketTopBar(
                title: viewModel.title,
                onBack: { viewModel.handleViewAction(.close) }
            )
            .padding(.top, Constants.topBarTopPadding)

            PolymarketCategoryTabsView(viewModel: viewModel.eventsViewModel)
        }
        .readGeometry(\.size.height, bindTo: $headerHeight)
        .background {
            Fade(position: .top)
                .blurred()
                .backgroundColor(DesignSystem.Color.bgPrimary)
                .ignoresSafeArea(edges: .top)
        }
    }

    private var content: some View {
        ScrollView(showsIndicators: false) {
            PolymarketEventsListView(viewModel: viewModel.eventsViewModel)
                .padding(.top, Constants.contentTopPadding)
        }
        .safeAreaInset(edge: .top, spacing: 0) {
            Color.clear.frame(height: headerHeight)
        }
        .refreshable { await viewModel.refresh() }
    }
}

// MARK: - Constants

private extension PolymarketCategoryView {
    enum Constants {
        static let topBarTopPadding: CGFloat = 8
        static let contentTopPadding: CGFloat = 8
    }
}
