//
//  LendingPairIcon.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUI

struct LendingPairIcon: View {
    let tokenImageUrl: URL?

    var body: some View {
        ZStack {
            TokenIcon(
                tokenIconInfo: .init(
                    name: "",
                    blockchainIconAsset: nil,
                    imageURL: tokenImageUrl,
                    isCustom: false,
                    customTokenColor: nil
                ),
                size: .init(bothDimensions: 48)
            )
            .offset(x: -16)

            Assets.YieldModule.yieldModuleAaveLogo.image
                .resizable()
                .scaledToFit()
                .frame(size: IconViewSizeSettings.tokenDetails.iconSize)
                .background(
                    Circle()
                        .fill(Colors.Background.tertiary)
                        .frame(width: 50, height: 50)
                )
                .offset(x: 16)
        }
    }
}
