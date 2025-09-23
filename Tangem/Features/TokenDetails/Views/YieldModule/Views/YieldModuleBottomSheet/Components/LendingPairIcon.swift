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
    let tokenId: String?

    var body: some View {
        ZStack {
            TokenIcon(tokenIconInfo: TokenIconInfoBuilder().build(from: tokenId), size: IconViewSizeSettings.tokenDetails.iconSize)
                .offset(x: -16)

            aaveLogo
                .offset(x: 16)
        }
    }

    private var aaveLogo: some View {
        Assets.YieldModule.yieldModuleAaveLogo.image
            .resizable()
            .scaledToFit()
            .frame(size: IconViewSizeSettings.tokenDetails.iconSize)
            .background(
                Circle()
                    .fill(Colors.Background.tertiary)
                    .frame(width: 50, height: 50)
            )
    }
}
