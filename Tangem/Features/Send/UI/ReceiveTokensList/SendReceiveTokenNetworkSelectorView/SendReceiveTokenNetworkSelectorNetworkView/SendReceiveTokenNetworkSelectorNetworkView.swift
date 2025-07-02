//
//  SendReceiveTokenNetworkSelectorNetworkView.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUI

struct SendReceiveTokenNetworkSelectorNetworkView: View {
    let viewModel: SendReceiveTokenNetworkSelectorNetworkViewData

    var body: some View {
        Button(action: viewModel.tapAction) {
            HStack(alignment: .center, spacing: 12) {
                IconView(url: viewModel.iconURL, size: CGSize(width: 36, height: 36), forceKingfisher: true)

                HStack(alignment: .center, spacing: 4) {
                    Text(viewModel.name)
                        .style(Fonts.Bold.subheadline, color: viewModel.isAvailable ? Colors.Text.primary1 : Colors.Text.disabled)

                    Text(viewModel.symbol)
                        .style(Fonts.Regular.caption1, color: viewModel.isAvailable ? Colors.Text.tertiary : Colors.Text.disabled)
                }

                Spacer()
            }
        }
        .disabled(!viewModel.isAvailable)
    }
}
