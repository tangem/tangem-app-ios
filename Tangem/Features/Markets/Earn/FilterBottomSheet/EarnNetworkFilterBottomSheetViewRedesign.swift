//
//  EarnNetworkFilterBottomSheetViewRedesign.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI
import TangemAssets
import TangemLocalization

struct EarnNetworkFilterBottomSheetViewRedesign: View {
    @ObservedObject private var viewModel: EarnNetworkFilterBottomSheetViewModel

    @ScaledMetric private var headerHorizontalPadding: CGFloat
    @ScaledMetric private var contentSpacing: CGFloat
    @ScaledMetric private var contentHorizontalPadding: CGFloat
    @ScaledMetric private var contentTitleTopPadding: CGFloat
    @ScaledMetric private var cancelPadding: CGFloat

    init(viewModel: EarnNetworkFilterBottomSheetViewModel) {
        self.viewModel = viewModel

        _headerHorizontalPadding = ScaledMetric(wrappedValue: .unit(.x3))
        _contentSpacing = ScaledMetric(wrappedValue: .unit(.x3))
        _contentHorizontalPadding = ScaledMetric(wrappedValue: .unit(.x4))
        _contentTitleTopPadding = ScaledMetric(wrappedValue: .unit(.x4))
        _cancelPadding = ScaledMetric(wrappedValue: .unit(.x4))
    }

    var body: some View {
        VStack(spacing: 0) {
            header
                .padding(.horizontal, headerHorizontalPadding)

            ScrollView(.vertical, showsIndicators: false) {
                content
                    .padding(.horizontal, contentHorizontalPadding)
            }

            cancelButton
                .padding(cancelPadding)
        }
        .background(Color.Tangem.Surface.level3)
    }
}

// MARK: - Subviews

private extension EarnNetworkFilterBottomSheetViewRedesign {
    var header: some View {
        BottomSheetHeaderView(
            title: viewModel.title,
            trailing: { closeButton }
        )
    }

    var content: some View {
        VStack(spacing: contentSpacing) {
            GroupedSection(viewModel.presetRowViewModels) { data in
                EarnNetworkFilterSelectedRowView(data: data, selection: viewModel.selectionBinding)
            }
            .separatorStyle(.none)
            .settings(\.backgroundColor, Color.Tangem.Surface.level2)

            GroupedSection(
                viewModel.networkRowInputs,
                content: { input in
                    EarnNetworkFilterNetworkRowViewRedesign(input: input)
                },
                header: {
                    DefaultHeaderView(Localization.earnFilterNetworks)
                        .padding(.top, contentTitleTopPadding)
                }
            )
            .separatorStyle(.none)
            .settings(\.backgroundColor, Color.Tangem.Surface.level2)
        }
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
