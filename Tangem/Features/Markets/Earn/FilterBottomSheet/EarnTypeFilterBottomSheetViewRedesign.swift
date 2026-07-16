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

struct EarnTypeFilterBottomSheetViewRedesign: View {
    @ObservedObject private var viewModel: EarnTypeFilterBottomSheetViewModel

    init(viewModel: EarnTypeFilterBottomSheetViewModel) {
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

private extension EarnTypeFilterBottomSheetViewRedesign {
    var content: some View {
        GroupedSection(viewModel.listOptionViewModel) {
            EarnNetworkFilterSelectedRowView(data: $0, selection: $viewModel.currentSelection)
        }
        .separatorStyle(.none)
        .horizontalPadding(.unit(.x4))
        .cornerRadius(.unit(.x6))
        .settings(\.backgroundColor, Color.Tangem.Surface.level3)
    }
}
