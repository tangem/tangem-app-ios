//
//  TangemPayIssuingCardDetailsView.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemLocalization
import TangemUI

struct TangemPayIssuingCardDetailsView: View {
    var body: some View {
        VStack {
            HStack(alignment: .top) {
                HStack(alignment: .center, spacing: 6) {
                    Image(systemName: "cloud.fill")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(height: 10)
                        .foregroundColor(Colors.Text.constantWhite)

                    Text(Localization.tangempayDigitalCard)
                        .style(Fonts.Bold.footnote, color: Colors.Text.constantWhite)
                }
                .padding(.top, 4)

                Spacer()

                Assets.Visa.logo.image
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(height: 38)
            }

            Spacer()
        }
        .padding(16)
        .aspectRatio(Constants.plasticCardStandardWidthToHeightRatio, contentMode: .fit)
        .background(
            Assets.Visa.cardOverlay.image
                .resizable()
                .aspectRatio(contentMode: .fill)
        )
        .background(Color.Tangem.Visa.cardDetailBackground, in: RoundedRectangle(cornerRadius: 14))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay {
            RoundedRectangle(cornerRadius: 14)
                .stroke(
                    LinearGradient(stops: [
                        .init(color: Colors.Stroke.primary.opacity(0.1), location: 0),
                        .init(color: Colors.Stroke.primary, location: 1),
                    ], startPoint: .bottomLeading, endPoint: .topTrailing),
                    lineWidth: 2
                )
        }
    }
}

private extension TangemPayIssuingCardDetailsView {
    enum Constants {
        static let plasticCardStandardWidthToHeightRatio = 1.586
    }
}
