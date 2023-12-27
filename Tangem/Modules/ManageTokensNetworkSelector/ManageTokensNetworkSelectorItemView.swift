//
//  ManageTokensNetworkSelectorItemView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI

struct ManageTokensNetworkSelectorItemView: View {
    @ObservedObject var viewModel: ManageTokensNetworkSelectorItemViewModel

    var body: some View {
        HStack(spacing: 12) {
            NetworkIcon(
                imageName: viewModel.iconName,
                isActive: false,
                isMainIndicatorVisible: viewModel.isMain,
                size: CGSize(bothDimensions: 36)
            )

            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(viewModel.networkName)
                    .lineLimit(1)
                    .layoutPriority(-1)
                    .style(Fonts.Bold.subheadline, color: Colors.Text.primary1)

                if let tokenTypeName = viewModel.tokenTypeName {
                    Text(tokenTypeName)
                        .lineLimit(1)
                        .style(Fonts.Regular.caption1, color: Colors.Text.tertiary)
                }
            }

            Spacer(minLength: 0)

            Toggle("", isOn: $viewModel.selectedPublisher)
                .labelsHidden()
                .toggleStyleCompat(Colors.Control.checked)
                .disabled(!viewModel.isAvailable)
        }
        .contentShape(Rectangle())
        .onTapGesture {} // fix scroll/longpress conflict
        .onLongPressGesture(perform: viewModel.onCopy)
        .padding(16)
    }
}

struct ManageTokensNetworkSelectorItemView_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            ManageTokensNetworkSelectorItemView(viewModel: .init(id: 0, isMain: true, iconName: "ethereum", iconNameSelected: "ethereum.fill", networkName: "Ethereum", tokenTypeName: "ERC20", contractAddress: nil, isSelected: .constant(true), isCopied: .constant(false)))

            ManageTokensNetworkSelectorItemView(viewModel: .init(id: 1, isMain: false, iconName: "solana", iconNameSelected: "solana.fill", networkName: "Solana", tokenTypeName: nil, contractAddress: nil, isSelected: .constant(false), isCopied: .constant(false)))

            ManageTokensNetworkSelectorItemView(viewModel: .init(id: 2, isMain: false, iconName: "bsc", iconNameSelected: "bsc.fill", networkName: "Binance smartest chain on the planet", tokenTypeName: "BEEP-BEEP 20", contractAddress: nil, isSelected: .constant(false), isCopied: .constant(false)))
        }
        .previewLayout(.fixed(width: 400, height: 300))
    }
}
