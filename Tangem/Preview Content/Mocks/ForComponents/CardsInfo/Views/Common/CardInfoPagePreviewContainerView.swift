//
//  CardInfoPagePreviewContainerView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUI
import TangemFoundation

struct CardInfoPagePreviewContainerView: View {
    @StateObject private var previewProvider = CardsInfoPagerPreviewProvider()
    @State private var selectedIndex: Int

    private let hasPullToRefresh: Bool

    init(
        previewConfig: CardInfoPagePreviewConfig
    ) {
        _selectedIndex = .init(initialValue: previewConfig.initiallySelectedIndex)
        hasPullToRefresh = previewConfig.hasPullToRefresh
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Colors.Background.secondary
                    .ignoresSafeArea()

                CardsInfoPagerView(
                    data: previewProvider.pages,
                    refreshScrollViewStateObject: hasPullToRefresh ? previewProvider.refreshScrollViewStateObject : nil,
                    selectedIndex: $selectedIndex,
                    headerViewBuilder: { pageViewModel in
                        MainHeaderView(viewModel: pageViewModel.header)
                            .cornerRadius(14.0)
                    },
                    contentViewBuilder: { pageViewModel in
                        CardInfoPagePreviewView(viewModel: pageViewModel)
                    },
                    bottomOverlayViewBuilder: { _ in EmptyView() },
                    footerOverlayViewBuilder: { _ in EmptyView() }
                )
                .pageSwitchThreshold(0.4)
                .contentViewVerticalOffset(64.0)
                .horizontalScrollDisabled(previewProvider.isHorizontalScrollDisabled)
                .navigationTitle("CardsInfoPagerView")
                .navigationBarTitleDisplayMode(.inline)
            }
        }
    }
}
