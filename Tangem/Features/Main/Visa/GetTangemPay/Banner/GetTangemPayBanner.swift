//
//  GetTangemPayBanner.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemFoundation
import TangemLocalization
import TangemAssets

struct GetTangemPayBannerView: View {
    var viewModel: GetTangemPayBannerViewModel

    var body: some View {
        HStack(spacing: 12) {
            Assets.Visa.cardBanner.image
                .resizable()
                .scaledToFill()
                .frame(width: 34, height: 71)
                .offset(y: 4)
                .padding(.leading, 8)

            VStack(alignment: .leading, spacing: 4) {
                Text(Localization.tangempayTangemVisaCard)
                    .style(
                        Fonts.BoldStatic.footnote,
                        color: Colors.Text.constantWhite
                    )

                Text(Localization.tangempayGetBannerDescription)
                    .style(
                        Fonts.RegularStatic.caption1,
                        color: Colors.Text.tertiary
                    )
            }
            .padding(.leading, 12)

            Spacer()
        }
        .onTapGesture {
            viewModel.bannerTapped()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 4)
        .background {
            EllipticalGradient(stops: [
                .init(color: Color.Tangem.Visa.bannerGradientStart, location: 0),
                .init(color: Color.Tangem.Visa.cardDetailBackground, location: 1),
            ], center: .init(x: 0.11, y: 0.71))
        }
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(alignment: .topTrailing) {
            Button {
                viewModel.closeBanner()
            } label: {
                Assets.cross.image
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .foregroundStyle(Colors.Icon.informative)
                    .frame(size: .init(bothDimensions: 20))
            }
            .padding(8)
        }
    }
}
