//
//  FeeSelectorCustomFeeRowView.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI
import TangemAssets

struct FeeSelectorCustomFeeRowView: View {
    @ObservedObject var viewModel: FeeSelectorCustomFeeRowViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 4) {
                Text(viewModel.title)
                    .style(Fonts.Bold.footnote, color: Colors.Text.tertiary)

                if let tooltip = viewModel.tooltip {
                    InfoButtonView(size: .small, tooltipText: tooltip)
                }
            }

            HStack(spacing: 4) {
                SendDecimalNumberTextField(
                    viewModel: viewModel.textFieldViewModel,
                    accessibilityIdentifier: viewModel.accessibilityIdentifier
                )
                .alignment(.leading)
                .appearance(.init(font: Fonts.Regular.subheadline, textColor: Colors.Text.primary1))
                .prefixSuffixOptions(.suffix(text: viewModel.suffix, hasSpace: true))
                .onFocusChanged(viewModel.onFocusChanged)
                .disabled(!viewModel.isEditable)

                Spacer()

                if let alternativeAmount = viewModel.alternativeAmount {
                    Text(alternativeAmount)
                        .style(Fonts.Bold.footnote, color: Colors.Text.tertiary)
                        .accessibilityIdentifier(viewModel.alternativeAmountAccessibilityIdentifier)
                }
            }
        }
    }
}
