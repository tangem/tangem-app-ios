//
//  ExpressApproveView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemLocalization
import TangemAssets
import TangemUI

struct ExpressApproveView: View {
    @ObservedObject private var viewModel: ExpressApproveViewModel

    init(viewModel: ExpressApproveViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        VStack(spacing: 22) {
            GroupedSection(viewModel.menuRowViewModel) {
                DefaultMenuRowView(viewModel: $0, selection: $viewModel.selectedAction, titleFont: Fonts.Regular.body)
            } footer: {
                approveInfoDescriptionView
            }
            .backgroundColor(Colors.Background.action)

            GroupedSection(viewModel.feeCompactViewModel) { feeViewModel in
                FeeCompactView(viewModel: feeViewModel) {
                    viewModel.didTapFeeSelectorButton()
                }
            } footer: {
                DefaultFooterView(viewModel.feeFooterText)
            }
            .backgroundColor(Colors.Background.action)
        }
        .padding(.top, 10)
        .padding(.bottom, 6)
        .padding(.horizontal, 16)
        .background(Colors.Background.tertiary)
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
