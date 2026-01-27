//
//  TangemPayKYCStatusPopupView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI
import TangemAssets
import TangemLocalization

struct TangemPayKYCStatusPopupView: View {
    var viewModel: TangemPayKYCStatusPopupViewModel

    var body: some View {
        VStack(spacing: 24) {
            Assets.Visa.promo.image
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(size: .init(bothDimensions: 56))
                .padding(.top, 64)

            VStack(spacing: 12) {
                Text(Localization.tangempayKycInProgress)
                    .style(
                        Fonts.BoldStatic.title3,
                        color: Colors.Text.primary1
                    )

                Text(Localization.tangempayKycInProgressPopupDescription)
                    .style(
                        Fonts.RegularStatic.subheadline,
                        color: Colors.Text.secondary
                    )
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 16)

            VStack(spacing: 8) {
                MainButton(settings: viewModel.viewStatusSettings)

                MainButton(settings: viewModel.cancelKYCSettings)
            }
        }
        .overlay(alignment: .topTrailing) {
            CircleButton
                .close(action: viewModel.dismiss)
                .size(.small)
                .padding(.top, 8)
        }
        .padding(.bottom, 12)
        .padding(.horizontal, 16)
        .frame(maxWidth: .infinity)
    }
}
