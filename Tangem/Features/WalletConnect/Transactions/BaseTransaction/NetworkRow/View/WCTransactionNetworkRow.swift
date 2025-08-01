//
//  WCTransactionNetworkRow.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import BlockchainSdk
import TangemAssets
import TangemUI
import TangemLocalization

struct WCTransactionNetworkRow: View {
    let viewModel: WCTransactionNetworkRowViewModel

    init(blockchain: Blockchain) {
        viewModel = .init(blockchain: blockchain)
    }

    var body: some View {
        HStack(spacing: 8) {
            Assets.Glyphs.networkNew.image
                .resizable()
                .frame(width: 24, height: 24)
                .foregroundStyle(Colors.Icon.accent)

            Text(Localization.wcCommonNetwork)
                .style(Fonts.Regular.body, color: Colors.Text.primary1)

            Spacer()

            Text(viewModel.blockchainName)
                .style(Fonts.Regular.body, color: Colors.Text.tertiary)

            viewModel.blockchainIcon.image
                .resizable()
                .frame(size: .init(bothDimensions: 20))
        }
        .lineLimit(1)
    }
}
