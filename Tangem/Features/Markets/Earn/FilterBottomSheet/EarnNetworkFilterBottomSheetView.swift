//
//  EarnNetworkFilterBottomSheetView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUI

struct EarnNetworkFilterBottomSheetView: View {
    @ObservedObject var viewModel: EarnNetworkFilterBottomSheetViewModel

    var body: some View {
        VStack(spacing: .zero) {
            header

            ScrollView(.vertical, showsIndicators: false) {
                content
            }
        }
        .background(Colors.Background.tertiary)
    }
}

// MARK: - Layout

extension EarnNetworkFilterBottomSheetView {
    enum Layout {
        static let horizontalPadding: CGFloat = 16
        static let verticalPadding: CGFloat = 12
        static let bottomPadding: CGFloat = 6
        static let sectionSpacing: CGFloat = 14
    }
}

// MARK: - Subviews

private extension EarnNetworkFilterBottomSheetView {
    var header: some View {
        BottomSheetHeaderView(title: viewModel.title)
            .padding(.horizontal, Layout.horizontalPadding)
            .padding(.vertical, Layout.verticalPadding)
    }

    var content: some View {
        VStack(spacing: Layout.sectionSpacing) {
            GroupedSection(viewModel.presetRowViewModels) { data in
                DefaultSelectableRowView(data: data, selection: viewModel.selectionBinding)
            }
            .settings(\.backgroundColor, Colors.Background.action)

            GroupedSection(viewModel.networkRowInputs) { input in
                EarnNetworkFilterNetworkRowView(input: input)
            }
            .settings(\.backgroundColor, Colors.Background.action)
        }
        .padding(.horizontal, Layout.horizontalPadding)
        .padding(.bottom, Layout.bottomPadding)
    }
}
