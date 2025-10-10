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
    @Binding var shouldAnimateBestRateBadge: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: .zero) {
            BaseOneLineRow(icon: Assets.Glyphs.stackNew, title: Localization.expressProvider) {
                providerView
            }
            .shouldShowTrailingIcon(data.isTappable)
            // We use 11 to save default 46 row height
            .padding(.vertical, 11)

            if data.isFCAWarningList {
                HStack(spacing: 4) {
                    Assets.infoCircle20.image
                        .resizable()
                        .renderingMode(.template)
                        .foregroundStyle(Colors.Text.tertiary)
                        .frame(width: 20, height: 20)

                    Text(Localization.expressProviderInFcaWarningList)
                        .style(Fonts.Regular.footnote, color: Colors.Text.tertiary)
                }
                .padding(.top, 4)
                .padding(.bottom, 12)
            }
        }
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
            ZStack(alignment: .bottomLeading) {
                HStack(spacing: 6) {
                    IconView(
                        url: provider.provider.imageURL,
                        size: CGSize(width: 20, height: 20),
                        forceKingfisher: true
                    )

                    Text(provider.provider.name)
                        .style(Fonts.Regular.body, color: Colors.Text.tertiary)
                        .lineLimit(1)
                }

                if data.isBest {
                    SendSwapProviderBestRateAnimationBadgeView(shouldAnimate: $shouldAnimateBestRateBadge)
                        .offset(x: 11.5, y: 5.5)
                }
            }
        }
    }
}
