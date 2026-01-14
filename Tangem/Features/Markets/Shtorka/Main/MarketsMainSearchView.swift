//
//  MarketsMainSearchView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import Combine
import TangemAssets
import TangemUI
import TangemUIUtils
import TangemFoundation
import TangemLocalization

struct MarketsMainSearchView: View {
    private var overlayHeight: CGFloat { searchResultListOverlayTotalHeight }

    let headerHeight: CGFloat
    let scrollTopAnchorId: UUID
    let scrollViewFrameCoordinateSpaceName: UUID
    let searchResultListOverlayTotalHeight: CGFloat
    let mainWindowSize: CGSize
    let updateListOverlayAppearance: (CGPoint) -> Void

    @ObservedObject var viewModel: MarketsTokenListViewModel

    var body: some View {
        list
    }

    // MARK: - Private Implementation

    @ViewBuilder
    private var list: some View {
        ScrollViewReader { proxy in
            ScrollView(showsIndicators: false) {
                // ScrollView inserts default spacing between its content views.
                // Wrapping content into a `VStack` prevents it.
                VStack(spacing: .zero) {
                    Color.clear
                        .frame(height: 0)
                        .id(scrollTopAnchorId)

                    // Using plain old overlay + dummy `Color.clear` spacer in the scroll view due to the buggy
                    // `safeAreaInset(edge:alignment:spacing:content:)` iOS 15+ API which has both layout and touch-handling issues
                    Color.clear
                        .frame(height: headerHeight)

                    // Using plain old overlay + dummy `Color.clear` spacer in the scroll view due to the buggy
                    // `safeAreaInset(edge:alignment:spacing:content:)` iOS 15+ API which has both layout and touch-handling issues
                    Color.clear
                        .frame(height: overlayHeight)

                    LazyVStack(spacing: 0) {
                        ForEach(viewModel.tokenViewModels) {
                            MarketsItemView(viewModel: $0, cellWidth: mainWindowSize.width)
                        }

                        // Need for display list skeleton view
                        if case .loading = viewModel.tokenListLoadingState {
                            loadingSkeletons
                        }

                        if viewModel.shouldDisplayShowTokensUnderCapView {
                            MarketsTokensUnderCapView(onShowUnderCapAction: viewModel.onShowUnderCapAction)
                        }
                    }
                    .onReceive(viewModel.resetScrollPositionPublisher) { _ in
                        proxy.scrollTo(scrollTopAnchorId)
                    }
                }
                .readContentOffset(
                    inCoordinateSpace: .named(scrollViewFrameCoordinateSpaceName),
                    onChange: updateListOverlayAppearance
                )
            }
            .coordinateSpace(name: scrollViewFrameCoordinateSpaceName)
        }
    }

    private var loadingSkeletons: some View {
        ForEach(0 ..< 20) { _ in
            MarketsSkeletonItemView()
        }
    }
}
