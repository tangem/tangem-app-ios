//
//  TangemPayPinCheckView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemLocalization
import TangemUI
import TangemAssets

struct TangemPayPinCheckView: View {
    @ObservedObject var viewModel: TangemPayPinCheckViewModel

    var body: some View {
        VStack(spacing: 12) {
            Text(Localization.tangempayYourPinCode)
                .style(
                    Fonts.BoldStatic.title3,
                    color: Colors.Text.primary1
                )
                .padding(.top, 64)

            Text(Localization.tangempayComeBackIfForgetPin)
                .style(
                    Fonts.RegularStatic.subheadline,
                    color: Colors.Text.secondary
                )

            Color.clear
                .overlay {
                    Group {
                        switch viewModel.state {
                        case .loading:
                            ActivityIndicatorView()

                        case .loaded(let pin):
                            OnboardingPinStackView(
                                maxDigits: viewModel.pinCodeLength,
                                isDisabled: true,
                                pinText: .constant(pin)
                            )
                            .screenCaptureProtection()
                            .fixedSize()
                        }
                    }
                }
                .padding(.bottom, 108)
                .padding(.top, 8)
        }
        .frame(maxWidth: .infinity)
        .aspectRatio(1.15, contentMode: .fit)
        .clipShape(RoundedRectangle(cornerRadius: 28))
        .padding(.horizontal, 12)
        .padding(.bottom, 12)
        .overlay(alignment: .topTrailing) {
            CircleButton
                .close(action: viewModel.close)
                .size(.small)
                .padding(.top, 8)
                .padding(.trailing, 16)
        }
        .overlay(alignment: .bottom) {
            switch viewModel.state {
            case .loading:
                EmptyView()

            case .loaded:
                MainButton(
                    title: Localization.tangempayChangePinCode,
                    action: viewModel.changePin
                )
                .padding(.bottom, 16)
                .padding(.horizontal, 16)
            }
        }
    }
}
