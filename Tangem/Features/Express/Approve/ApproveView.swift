//
//  ApproveView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemLocalization
import TangemAssets
import TangemUI

struct ApproveView: View {
    @ObservedObject private var viewModel: ApproveViewModel

    init(viewModel: ApproveViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        VStack(spacing: 26) {
            GroupedSection(viewModel.menuRowViewModel) {
                DefaultMenuRowView(viewModel: $0, selection: $viewModel.selectedPolicy, titleFont: Fonts.Regular.body)
            } footer: {
                approveInfoDescriptionView
            }
            .backgroundColor(DesignSystem.Color.bgSecondary)

            GroupedSection(viewModel.feeCompactViewModel) { feeViewModel in
                FeeCompactView(viewModel: feeViewModel) {
                    viewModel.didTapFeeSelectorButton()
                }
            } footer: {
                DefaultFooterView(viewModel.feeFooterText)
            }
            .backgroundColor(DesignSystem.Color.bgSecondary)
        }
        .padding(.top, 4)
        .padding(.bottom, 2)
        .padding(.horizontal, 16)
        .background(DesignSystem.Color.bgPrimary)
        .disabled(viewModel.state.isContentLocked)
    }

    private var approveInfoDescriptionView: some View {
        Text(viewModel.approveInfoSubtitle())
            .environment(\.openURL, OpenURLAction { _ in
                viewModel.didTapLearnMore()
                return .handled
            })
            .multilineTextAlignment(.leading)
    }
}
