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
import TangemLocalization

struct EarnTypeFilterBottomSheetViewRedesign: View {
    @ObservedObject private var viewModel: EarnTypeFilterBottomSheetViewModel

    @ScaledMetric private var headerHorizontalPadding: CGFloat
    @ScaledMetric private var contentHorizontalPadding: CGFloat
    @ScaledMetric private var cancelPadding: CGFloat

    init(viewModel: EarnTypeFilterBottomSheetViewModel) {
        self.viewModel = viewModel

        _headerHorizontalPadding = ScaledMetric(wrappedValue: .unit(.x3))
        _contentHorizontalPadding = ScaledMetric(wrappedValue: .unit(.x4))
        _cancelPadding = ScaledMetric(wrappedValue: .unit(.x4))
    }

    var body: some View {
        VStack(spacing: .zero) {
            header
                .padding(.horizontal, headerHorizontalPadding)

            GroupedSection(viewModel.listOptionViewModel) {
                EarnNetworkFilterSelectedRowView(data: $0, selection: $viewModel.currentSelection)
            }
            .separatorStyle(.none)
            .settings(\.backgroundColor, Color.Tangem.Surface.level2)
            .padding(.horizontal, contentHorizontalPadding)

            cancelButton
                .padding(cancelPadding)
        }
        .background(Color.Tangem.Surface.level3)
    }
}

// MARK: - Subviews

private extension EarnTypeFilterBottomSheetViewRedesign {
    var header: some View {
        BottomSheetHeaderView(
            title: viewModel.title,
            trailing: { closeButton }
        )
    }

    var closeButton: some View {
        TangemButton(
            content: .icon(Assets.crossBig),
            action: viewModel.onCloseTap
        )
        .setStyleType(.secondary)
        .setCornerStyle(.rounded)
        .setSize(.x9)
    }

    var cancelButton: some View {
        TangemButton(
            content: .text(AttributedString(Localization.commonCancel)),
            action: viewModel.onCancelTap
        )
        .setStyleType(.secondary)
        .setCornerStyle(.rounded)
        .setHorizontalLayout(.infinity)
        .setSize(.x12)
    }
}
