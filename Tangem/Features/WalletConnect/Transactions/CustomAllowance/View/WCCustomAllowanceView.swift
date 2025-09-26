//
//  WCCustomAllowanceView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI
import TangemAssets
import TangemLocalization

struct WCCustomAllowanceView: View {
    @ObservedObject var viewModel: WCCustomAllowanceViewModel

    var body: some View {
        VStack(spacing: 0) {
            amountSection
                .padding(.bottom, 14)

            unlimitedToggleSection
                .padding(.bottom, 84)
        }
        .padding(.horizontal, 16)
    }

    private var amountSection: some View {
        HStack(spacing: 8) {
            VStack(spacing: 4) {
                Text(Localization.commonAmount)
                    .style(Fonts.Bold.footnote, color: Colors.Text.tertiary)
                    .frame(maxWidth: .infinity, alignment: .leading)

                TextField("0", text: $viewModel.amountText)
                    .style(Fonts.Regular.body, color: viewModel.isUnlimited ? Colors.Text.tertiary : Colors.Text.primary1)
                    .keyboardType(.decimalPad)
                    .disabled(viewModel.isUnlimited)
                    .multilineTextAlignment(.leading)
            }

            Spacer()

            tokenIconView
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(Colors.Background.action)
        .cornerRadius(14)
    }

    @ViewBuilder
    private var tokenIconView: some View {
        let iconSize = CGSize(bothDimensions: 40)
        let cornerRadius = WCAssetIconHelper.cornerRadius(for: viewModel.asset, iconSize: iconSize)

        if let iconURL = viewModel.tokenIconURL {
            IconView(url: iconURL, size: iconSize, cornerRadius: cornerRadius)
        } else {
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(Colors.Background.primary)
                .frame(size: iconSize)
                .overlay(
                    Text(String(viewModel.tokenSymbol.prefix(1)))
                        .style(Fonts.Bold.subheadline, color: Colors.Text.primary1)
                )
        }
    }

    private var unlimitedToggleSection: some View {
        HStack(spacing: 16) {
            Text(Localization.wcUnlimitedAmount)
                .style(Fonts.Regular.body, color: Colors.Text.primary1)
                .frame(maxWidth: .infinity, alignment: .leading)

            Toggle("", isOn: $viewModel.isUnlimited)
                .tint(Colors.Control.checked)
                .onChange(of: viewModel.isUnlimited) { newValue in
                    Task {
                        await viewModel.handleViewAction(.unlimitedToggled(newValue))
                    }
                }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(Colors.Background.action)
        .cornerRadius(14)
    }
}
