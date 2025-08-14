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

                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text(viewModel.name)
                        .style(Fonts.Bold.subheadline, color: Colors.Text.primary1)

                    if let network = viewModel.network {
                        Text(network)
                            .style(
                                Fonts.Regular.caption1,
                                color: viewModel.isMainNetwork ? Colors.Text.accent : Colors.Text.tertiary
                            )
                    }
                }

                Spacer()
            }
            .multilineTextAlignment(.leading)
        }
    }
}
