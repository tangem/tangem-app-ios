//
//  EarnTypeFilterBottomSheetViewRedesign.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUI
import TangemUIUtils

struct EarnTypeFilterBottomSheetViewRedesign: View {
    @ObservedObject private var viewModel: EarnTypeFilterBottomSheetViewModel

    @ScaledMetric private var horizontalPadding: CGFloat = 16
    @ScaledMetric private var titleHeight: CGFloat = 44
    @ScaledMetric private var titleVerticalPadding: CGFloat = 16

    init(viewModel: EarnTypeFilterBottomSheetViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        VStack(spacing: .zero) {
            header

            content
        }
        .padding(.horizontal, horizontalPadding)
        .accessibilityAction(.escape) { viewModel.onCloseTap() }
        .floatingSheetConfiguration { configuration in
            configuration.sheetBackground = .color(DesignSystem.Color.bgPrimary)
            configuration.backgroundInteractionBehavior = .tapToDismiss
            configuration.verticalSwipeBehavior = .init(target: .sheet, threshold: 100)
        }
    }
}

// MARK: - Subviews

private extension EarnTypeFilterBottomSheetViewRedesign {
    var header: some View {
        Text(viewModel.title)
            .style(DesignSystem.Font.bodyMediumToken, color: DesignSystem.Color.textPrimary)
            .frame(maxWidth: .infinity, minHeight: titleHeight)
            .padding(.vertical, titleVerticalPadding)
    }

    var content: some View {
        ScrollView(.vertical, showsIndicators: false) {
            EarnTypeFilterContentView(viewModel: viewModel)
        }
        .scrollBounceBehavior(.basedOnSize)
    }
}

struct EarnTypeFilterContentView: View {
    @ObservedObject var viewModel: EarnTypeFilterBottomSheetViewModel

    var body: some View {
        VStack(spacing: .zero) {
            ForEach(viewModel.listOptionViewModel) { data in
                EarnNetworkFilterSelectedRowView(data: data, selection: $viewModel.currentSelection)
            }
        }
    }
}
