//
//  TangemPayAddToApplePayBanner.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemLocalization

struct TangemPayAddToApplePayBanner: View {
    let closeAction: () -> Void

    var body: some View {
        HStack(spacing: 16) {
            Circle()
                .frame(width: 48, height: 48)
                .foregroundStyle(Color.white.opacity(0.1))
                .overlay {
                    Assets.Visa.appleWallet.image
                }

            VStack(alignment: .leading, spacing: 4) {
                Text(Localization.tangempayCardDetailsOpenWalletTitleApple)
                    .style(Fonts.Bold.footnote, color: Colors.Text.constantWhite)
                Text(Localization.tangempayCardDetailsOpenWalletNotificationSubtitleApple)
                    .style(Fonts.Regular.caption1, color: Colors.Text.tertiary)
            }
            .multilineTextAlignment(.leading)
            .infinityFrame(axis: .horizontal, alignment: .leading)
        }
        .padding()
        .background {
            Assets.Visa.bgAddToWallet.image
                .resizable()
                .scaledToFill()
        }
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(alignment: .topTrailing) {
            Button {
                closeAction()
            } label: {
                Assets.cross.image
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .foregroundStyle(Color.white)
                    .frame(size: .init(bothDimensions: 20))
            }
            .padding(8)
        }
    }
}
