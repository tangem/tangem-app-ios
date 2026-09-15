//
//  EarnDetailViewRedesign.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI
import TangemUIUtils
import TangemAssets
import TangemLocalization

struct EarnDetailViewRedesign: View {
    @ObservedObject var viewModel: EarnDetailViewModel

    @Injected(\.overlayContentStateObserver) private var overlayContentStateObserver: OverlayContentStateObserver

    @Environment(\.mainShtorkaSize) private var sheetSize

    @ScaledMetric private var contentSpacing: CGFloat = 16

    var body: some View {
        content
            .if(sheetSize.isFeedSheet) { view in
                view
                    .toolbar(.hidden, for: .navigationBar)
                    .navigationBarBackButtonHidden()
            }
            .onOverlayContentProgressChange(overlayContentStateObserver: overlayContentStateObserver) { [weak viewModel] progress in
                viewModel?.onOverlayContentProgressChange(progress)
            }
    }
}

// MARK: - Subviews

private extension EarnDetailViewRedesign {
    var content: some View {
        scrollContent
            .background(DesignSystem.Color.bgPrimary)
            .safeAreaInset(edge: .top, spacing: contentSpacing) {
                navigationBar
            }
    }

    var scrollContent: some View {
        ScrollView(.vertical, showsIndicators: false) {
            EarnContentView(viewModel: viewModel)
        }
        .opacity(viewModel.overlayContentHidingProgress)
    }

    var navigationBar: some View {
        NavigationHeader(
            leadingContent: { navigationBarLeadingButton },
            principalContent: { navigationTitle },
            trailingContent: { EmptyView() }
        )
    }

    @ViewBuilder
    var navigationBarLeadingButton: some View {
        switch viewModel.presentSource {
        case .navigation:
            NavigationBarButton.back(action: {
                viewModel.handleViewAction(.back)
            })
            .redesigned()
        case .deeplink:
            NavigationBarButton.close(action: {
                viewModel.handleViewAction(.back)
            })
            .redesigned()
        }
    }

    var navigationTitle: some View {
        Text(Localization.earnTitle)
            .style(DesignSystem.Font.bodyMediumToken, color: DesignSystem.Color.textPrimary)
    }
}
