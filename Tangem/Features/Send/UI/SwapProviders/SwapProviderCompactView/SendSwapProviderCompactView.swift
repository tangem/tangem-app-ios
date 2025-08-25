//
//  SendSwapProviderCompactView.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI
import TangemAssets
import TangemLocalization

struct SendSwapProviderCompactView: View {
    let data: SendSwapProviderCompactViewData

    var body: some View {
        BaseOneLineRow(icon: Assets.Glyphs.stackNew, title: Localization.expressProvider) {
            providerView
        }
        // We use 11 to save default 46 row height
        .padding(.vertical, 11)
        .padding(.horizontal, 14)
    }

    @ViewBuilder
    private var providerView: some View {
        switch data.provider {
        case .failure:
            Assets.redCircleWarning.image
                .resizable()
                .frame(width: 20, height: 20)
        case .loading:
            ProgressView()
        case .success(let provider):
            HStack(spacing: 6) {
                IconView(url: provider.imageURL, size: CGSize(width: 20, height: 20), forceKingfisher: true)

                Text(provider.name)
                    .style(Fonts.Regular.body, color: Colors.Text.tertiary)
                    .lineLimit(1)
            }
        }
    }
}
