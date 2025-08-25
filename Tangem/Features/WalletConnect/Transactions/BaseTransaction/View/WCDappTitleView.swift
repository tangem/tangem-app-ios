//
//  WCDappTitleView.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import Kingfisher
import TangemAssets
import TangemUI

struct WCDappTitleView: View {
    let dAppData: WalletConnectDAppData
    let isVerified: Bool
    let kingfisherImageCache: ImageCache

    var body: some View {
        HStack(spacing: 12) {
            iconView

            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .top, spacing: 4) {
                    Text(dAppData.name)
                        .lineLimit(2)
                        .style(Fonts.Bold.subheadline, color: Colors.Text.primary1)

                    if isVerified {
                        Assets.Glyphs.verified.image
                            .resizable()
                            .frame(width: 16, height: 16)
                            .foregroundStyle(Colors.Icon.accent)
                            .padding(.top, 2)
                    }
                }

                Text(dAppData.domain.host ?? "")
                    .lineLimit(1)
                    .style(Fonts.Regular.caption1, color: Colors.Text.tertiary)
            }
            .multilineTextAlignment(.leading)
        }
    }

    @ViewBuilder
    private var iconView: some View {
        ZStack {
            if let iconURL = dAppData.icon {
                remoteIcon(iconURL)
            } else {
                fallbackIconAsset
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private func remoteIcon(_ iconURL: URL) -> some View {
        KFImage(iconURL)
            .targetCache(kingfisherImageCache)
            .cancelOnDisappear(true)
            .resizable()
            .scaledToFill()
            .frame(width: 36, height: 36)
    }

    private var fallbackIconAsset: some View {
        Assets.Glyphs.explore.image
            .resizable()
            .scaledToFit()
            .frame(width: 20, height: 20)
            .foregroundStyle(Colors.Icon.accent)
            .frame(width: 36, height: 36)
            .background(Colors.Icon.accent.opacity(0.1))
    }
}
