//
//  AccountsAwareNetworkSelectorItemView.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI
import TangemAssets
import TangemLocalization
import TangemAccessibilityIdentifiers

struct AccountsAwareNetworkSelectorItemView: View {
    @ObservedObject var viewModel: AccountsAwareNetworkSelectorItemViewModel

    var body: some View {
        Button(action: viewModel.handleTap) {
            HStack(spacing: 8) {
                icon

                HStack(alignment: .firstTextBaseline, spacing: 2) {
                    Text(viewModel.networkName.uppercased())
                        .style(Fonts.Bold.subheadline, color: viewModel.networkNameForegroundColor)
                        .lineLimit(2)

                    if let contractName = viewModel.contractName {
                        Text(contractName)
                            .style(Fonts.Regular.caption1, color: viewModel.contractNameForegroundColor)
                            .padding(.leading, 2)
                            .lineLimit(1)
                            .fixedSize()
                    }
                }

                Spacer(minLength: 0)

                if viewModel.isReadonly {
                    CapsuleButton(title: Localization.commonAdded, action: {})
                        .tint(Colors.Control.unchecked)
                        .scaleEffect(0.8)
                        .disabled(viewModel.isReadonly)
                        .accessibilityIdentifier(TokenAccessibilityIdentifiers.networkSwitch(for: viewModel.networkName))
                }
            }
            .padding(.vertical, 16)
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .disabled(viewModel.isReadonly)
    }

    private var icon: some View {
        NetworkIcon(
            imageAsset: viewModel.iconImageAsset,
            isActive: true,
            isDisabled: viewModel.isReadonly,
            isMainIndicatorVisible: false,
            showBackground: false,
            size: .init(bothDimensions: 22)
        )
    }
}
