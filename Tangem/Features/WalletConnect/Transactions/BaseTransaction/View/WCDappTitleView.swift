//
//  WCDappTitleView.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUI
import ReownWalletKit

struct WCDappTitleView: View {
    private let icons: [URL]
    private let dappName: String
    private let dappUrl: String
    private let iconSideLength: CGFloat
    private let placeholderIconSideLength: CGFloat
    private let isVerified: Bool

    init(
        dAppData: WalletConnectDAppData,
        iconSideLength: CGFloat,
        isVerified: Bool,
        placeholderIconSideLength: CGFloat = 26
    ) {
        icons = [dAppData.icon].compactMap { $0 }
        dappName = dAppData.name
        dappUrl = dAppData.domain.host ?? ""
        self.isVerified = isVerified
        self.iconSideLength = iconSideLength
        self.placeholderIconSideLength = placeholderIconSideLength
    }

    var body: some View {
        content
    }

    private var content: some View {
        HStack(spacing: 16) {
            if let iconURL = icons.last {
                IconView(url: iconURL, size: .init(bothDimensions: iconSideLength))
            } else {
                ZStack {
                    Colors.Icon.accent.opacity(0.1)
                        .frame(size: .init(bothDimensions: iconSideLength))
                        .cornerRadius(8, corners: .allCorners)
                    Assets.Glyphs.explore.image
                        .renderingMode(.template)
                        .foregroundStyle(Colors.Icon.accent)
                        .frame(size: .init(bothDimensions: placeholderIconSideLength))
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                if dappName.isNotEmpty {
                    HStack(spacing: 8) {
                        Text(dappName)
                            .style(Fonts.Bold.title3, color: Colors.Text.primary1)

                        if isVerified {
                            Assets.Glyphs.verified.image
                                .foregroundStyle(Colors.Icon.accent)
                        }
                    }
                }

                if dappUrl.isNotEmpty {
                    Text(dappUrl)
                        .style(Fonts.Regular.footnote, color: Colors.Text.tertiary)
                }
            }
            .multilineTextAlignment(.leading)
        }
    }
}
