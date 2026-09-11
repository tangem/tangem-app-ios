//
//  TangemPayPlasticCardArtStubView.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets

// [REDACTED_TODO_COMMENT]
//
// An issued plastic card carries its own `cards[].images`, so the carousel will render it through the same
// `TangemPayCardDetailsViewRedesigned` as every other card and this bundled art becomes unnecessary.
struct TangemPayPlasticCardArtStubView: View {
    var body: some View {
        Assets.Visa.cardPlastic.image
            .resizable()
            .aspectRatio(Constants.cardWidthToHeightRatio, contentMode: .fit)
            .clipShape(RoundedRectangle(cornerRadius: Constants.cornerRadius, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: Constants.cornerRadius, style: .continuous)
                    .strokeBorder(Color.white.opacity(Constants.borderOpacity), lineWidth: Constants.borderWidth)
                    .allowsHitTesting(false)
            }
    }
}

private extension TangemPayPlasticCardArtStubView {
    enum Constants {
        /// Matches `TangemPayIssuingCardDetailsViewRedesigned` so both cards keep the same height in the
        /// carousel, even though the art itself is 370×238.
        static let cardWidthToHeightRatio = 1.586
        static let cornerRadius: CGFloat = 20
        static let borderOpacity: Double = 0.1
        static let borderWidth: CGFloat = 1
    }
}
