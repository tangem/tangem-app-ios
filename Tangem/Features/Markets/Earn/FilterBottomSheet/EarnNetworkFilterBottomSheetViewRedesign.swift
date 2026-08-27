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

    @ScaledMetric private var contentSpacing: CGFloat = 12
    @ScaledMetric private var contentTitleTopPadding: CGFloat = 16

    init(viewModel: EarnNetworkFilterBottomSheetViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        EarnFilterBottomSheetLayout(
            title: viewModel.title,
            onClose: viewModel.onCloseTap,
            onCancel: viewModel.onCancelTap
        ) {
            content
        }
    }
}

// MARK: - Subviews

private extension EarnNetworkFilterBottomSheetViewRedesign {
    var content: some View {
        VStack(spacing: contentSpacing) {
            GroupedSection(viewModel.presetRowViewModels) { data in
                EarnNetworkFilterSelectedRowView(data: data, selection: viewModel.selectionBinding)
            }
            .separatorStyle(.none)
            .horizontalPadding(16)
            .cornerRadius(24)
            .settings(\.backgroundColor, DesignSystem.Color.bgSecondary)

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
            .horizontalPadding(16)
            .cornerRadius(24)
            .settings(\.backgroundColor, DesignSystem.Color.bgSecondary)
        }
    }
}
