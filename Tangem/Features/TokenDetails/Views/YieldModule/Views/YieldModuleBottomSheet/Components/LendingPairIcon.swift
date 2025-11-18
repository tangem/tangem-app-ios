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
    let iconsSize: CGSize

    private var overlap: CGFloat { iconsSize.width * 0.4 }
    private let halo: CGFloat = 2

    private var iconUrl: URL? {
        tokenId.map { IconURLBuilder().tokenIconURL(id: $0, size: .large) }
    }

    var body: some View {
        HStack(spacing: -overlap) {
            IconView(url: iconUrl, size: iconsSize, forceKingfisher: true)
                .frame(size: iconsSize)
                .clipShape(Circle())

            aaveLogo
        }
        .padding(.horizontal, overlap / 2)
        .accessibilityHidden(true)
    }

    private var aaveLogo: some View {
        Assets.YieldModule.yieldModuleAaveLogo.image
            .resizable()
            .scaledToFit()
            .frame(size: iconsSize)
            .padding(halo)
            .background(Circle().fill(Colors.Background.tertiary))
    }
}
