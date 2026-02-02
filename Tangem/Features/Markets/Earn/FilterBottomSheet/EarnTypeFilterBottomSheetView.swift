//
//  EarnTypeFilterBottomSheetView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUI

struct EarnTypeFilterBottomSheetView: View {
    @ObservedObject var viewModel: EarnTypeFilterBottomSheetViewModel

    var body: some View {
        VStack(spacing: .zero) {
            BottomSheetHeaderView(title: viewModel.title)

            if viewModel.sections.isEmpty {
                GroupedSection(viewModel.listOptionViewModel) {
                    DefaultSelectableRowView(data: $0, selection: $viewModel.currentSelection)
                }
                .settings(\.backgroundColor, Colors.Background.action)
            } else {
                ScrollView {
                    VStack(spacing: 16) {
                        ForEach(viewModel.sections) { section in
                            GroupedSection(section.items) {
                                DefaultSelectableRowView(data: $0, selection: $viewModel.currentSelection)
                            }
                            .settings(\.backgroundColor, Colors.Background.action)
                        }
                    }
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 10)
    }
}
