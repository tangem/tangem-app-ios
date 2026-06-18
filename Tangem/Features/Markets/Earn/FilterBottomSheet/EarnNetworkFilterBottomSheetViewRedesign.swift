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

    @ScaledMetric private var contentSpacing: CGFloat = .unit(.x3)
    @ScaledMetric private var contentTitleTopPadding: CGFloat = .unit(.x4)

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
            .horizontalPadding(.unit(.x4))
            .cornerRadius(.unit(.x6))
            .settings(\.backgroundColor, Color.Tangem.Surface.level3)

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
            .horizontalPadding(.unit(.x4))
            .cornerRadius(.unit(.x6))
            .settings(\.backgroundColor, Color.Tangem.Surface.level3)
        }
    }
}
