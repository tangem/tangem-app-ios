//
//  TangemPayKYCDeclinedPopupView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI
import TangemAssets
import TangemLocalization

struct TamgemPayKYCDeclinedPopupView: View {
    var viewModel: TangemPayKYCDeclinedPopupViewModel

    var body: some View {
        VStack(spacing: 24) {
            Assets.Visa.kycDeclinedBrokenHeart.image
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(size: .init(bothDimensions: 56))
                .padding(.top, 64)

            VStack(spacing: 12) {
                Text(Localization.tangempayKycRejected)
                    .style(
                        Fonts.BoldStatic.title3,
                        color: Colors.Text.primary1
                    )

                Text(AttributedString.description)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 16)

            VStack(spacing: 8) {
                MainButton(settings: viewModel.openSupportButton)

                MainButton(settings: viewModel.hideKYCButton)
            }
        }
        .overlay(alignment: .topTrailing) {
            NavigationBarButton.close(action: viewModel.dismiss)
                .padding(.top, 8)
        }
        .padding(.bottom, 12)
        .padding(.horizontal, 16)
        .frame(maxWidth: .infinity)
    }
}

private extension AttributedString {
    static var description: Self {
        var start = AttributedString(Localization.tangempayKycRejectedDescription + " ")
        start.foregroundColor = Colors.Text.secondary

        var end = AttributedString(Localization.tangempayKycRejectedDescriptionSpan)
        end.foregroundColor = Colors.Text.accent

        return start + end
    }
}
