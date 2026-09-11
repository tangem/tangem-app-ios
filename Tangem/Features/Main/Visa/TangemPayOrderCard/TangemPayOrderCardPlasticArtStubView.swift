//
//  TangemPayOrderCardPlasticArtStubView.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets

// [REDACTED_TODO_COMMENT]
//
// The virtual card on this screen already draws `customerTariffPlan.tariffPlan.images` of type `MAIN`, but
// nothing in `customer/me` or `customer/offers` carries art for a card type that has not been issued yet.
// When it does, replace the call site with the same `KFImage(…).placeholder { … }` the virtual card uses.
struct TangemPayOrderCardPlasticArtStubView: View {
    let size: CGSize

    var body: some View {
        Assets.Visa.cardEarlybirds.image
            .resizable()
            .frame(width: Constants.artWidth, height: Constants.artHeight)
            .offset(y: Constants.shadowOffset)
            .frame(width: size.width, height: size.height)
    }
}

private extension TangemPayOrderCardPlasticArtStubView {
    enum Constants {
        /// `card-earlybirds` bakes its drop shadow into the canvas, insetting the card body by 40pt
        /// horizontally, 32pt from the top and 48pt from the bottom — hence the size and the downward offset.
        static let artWidth: CGFloat = 346
        static let artHeight: CGFloat = 252
        static let shadowOffset: CGFloat = 8
    }
}
