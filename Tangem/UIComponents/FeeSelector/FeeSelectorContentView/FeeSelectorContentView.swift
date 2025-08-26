//
//  FeeSelectorView.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI
import TangemUIUtils
import TangemLocalization
import TangemAssets

struct FeeSelectorContentView: View {
    @ObservedObject var viewModel: FeeSelectorContentViewModel

    var body: some View {
        VStack(spacing: .zero) {
            BottomSheetHeaderView(
                title: Localization.commonNetworkFeeTitle,
                leading: backButton,
                trailing: closeButton
            )
            .padding(.vertical, 4)
            .padding(.horizontal, 16)

            ScrollView {
                SelectableSection(viewModel.feesRowData) { data in
                    FeeSelectorContentRowView(viewModel: data, isSelected: viewModel.isSelected(data.feeOption).asBinding)
                }
                // Should start when title starts (14 + 36 + 12)
                .separatorPadding(.init(leading: 62, trailing: 14))
                .padding(.horizontal, 14)
            }
            .scrollBounceBehaviorBackport(.basedOnSize)

            MainButton(title: Localization.commonDone, action: viewModel.done)
                .padding(.vertical, 16)
                .padding(.horizontal, 16)
        }
        .onAppear(perform: viewModel.onAppear)
        .floatingSheetConfiguration { configuration in
            configuration.sheetBackgroundColor = Colors.Background.action
            configuration.sheetFrameUpdateAnimation = .easeInOut
            configuration.backgroundInteractionBehavior = .tapToDismiss
        }
    }

    @ViewBuilder
    private func backButton() -> some View {
        if case .back = viewModel.dismissButtonType {
            CircleButton.back(action: viewModel.dismiss)
        }
    }

    @ViewBuilder
    private func closeButton() -> some View {
        if case .close = viewModel.dismissButtonType {
            CircleButton.close(action: viewModel.dismiss)
        }
    }
}
