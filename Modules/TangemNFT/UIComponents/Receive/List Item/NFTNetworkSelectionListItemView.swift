//
//  NFTNetworkSelectionListItemView.swift
//  TangemNFT
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI
import TangemUI
import TangemAssets

struct NFTNetworkSelectionListItemView: View {
    let viewData: NFTNetworkSelectionListItemViewData

    private var textColor: Color {
        viewData.isAvailable ? Colors.Text.primary1 : Colors.Text.disabled
    }

    var body: some View {
        HStack(spacing: 12.0) {
            TokenIcon(tokenIconInfo: viewData.tokenIconInfo, size: .init(bothDimensions: 24.0))
                .saturation(viewData.isAvailable ? 1.0 : 0.0)

            Text(viewData.title)
                .style(Fonts.Bold.subheadline.weight(.medium), color: textColor)

            Spacer()
        }
        .padding(.vertical, 14.0)
    }
}

// MARK: - Previews

#if DEBUG
#Preview {
    NFTNetworkSelectionListItemView(
        viewData: .init(
            title: "Ethereum",
            tokenIconInfo: .init(
                name: "eth",
                blockchainIconAsset: nil,
                imageURL: nil,
                isCustom: false,
                customTokenColor: nil
            ),
            isAvailable: true,
            tapAction: { print("on item tap") }
        )
    )
}
#endif // DEBUG
