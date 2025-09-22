//
//  SendFeeView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemLocalization
import TangemAssets
import TangemUI

struct SendFeeView: View {
    @ObservedObject var viewModel: SendFeeViewModel

    var body: some View {
        GroupedScrollView(spacing: 20) {
            Group {
                GroupedSection(viewModel.feeRowViewModels) { feeRowViewModel in
                    FeeRowView(viewModel: feeRowViewModel)
                        .accessibilityIdentifier(feeRowViewModel.option.accessibilityIdentifier)
                } footer: {
                    feeSelectorFooter
                }
                .settings(\.backgroundColor, Colors.Background.action)

                if let input = viewModel.networkFeeUnreachableNotificationViewInput {
                    NotificationView(input: input)
                }

                if !viewModel.customFeeModels.isEmpty {
                    ForEach(viewModel.customFeeModels) { customFeeModel in
                        SendCustomFeeInputField(viewModel: customFeeModel)
                            .onFocusChanged(customFeeModel.onFocusChanged)
                    }
                }
            }
        }
        .onAppear(perform: viewModel.onAppear)
    }

    private var feeSelectorFooter: some View {
        Text(.init(viewModel.feeSelectorFooterText))
            .style(Fonts.Regular.caption1, color: Colors.Text.tertiary)
            .environment(\.openURL, OpenURLAction { url in
                viewModel.openFeeExplanation()
                return .handled
            })
    }
}
