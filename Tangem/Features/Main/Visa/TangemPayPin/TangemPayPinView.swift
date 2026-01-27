//
//  TangemPayPinView.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemLocalization
import TangemAssets
import TangemUI

struct TangemPayPinView: View {
    @ObservedObject var viewModel: TangemPayPinViewModel

    var body: some View {
        NavigationStack {
            Group {
                switch viewModel.state {
                case .enterPin:
                    enterPinView
                case .created:
                    createdView
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if viewModel.state == .enterPin {
                        Button(action: viewModel.close) {
                            Text(Localization.commonClose)
                                .style(Fonts.Regular.body, color: Colors.Text.primary1)
                        }
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var enterPinView: some View {
        VStack(spacing: 0) {
            Spacer()
                .frame(minHeight: 0)

            VStack(spacing: 40) {
                VStack(spacing: 10) {
                    Text(Localization.tangempaySetPinCode)
                        .style(Fonts.Bold.title1, color: Colors.Text.primary1)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)

                    Text(Localization.visaOnboardingPinCodeDescription)
                        .style(Fonts.Regular.callout, color: Colors.Text.secondary)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.horizontal, 40)

                VStack(spacing: 4) {
                    OnboardingPinStackView(
                        maxDigits: viewModel.pinCodeLength,
                        isDisabled: viewModel.isLoading,
                        pinText: $viewModel.pin
                    )

                    Text(viewModel.errorMessage ?? " ")
                        .lineLimit(2)
                        .multilineTextAlignment(.center)
                        .style(Fonts.Regular.footnote, color: Colors.Text.warning)
                        .hidden(viewModel.errorMessage == nil)
                        .padding(.horizontal, 16)
                }
            }

            Spacer()
                .frame(minHeight: 0)
            Spacer()
                .frame(minHeight: 0)

            MainButton(
                title: Localization.commonSubmit,
                isLoading: viewModel.isLoading,
                isDisabled: !viewModel.isPinCodeValid,
                action: viewModel.submit
            )
            .padding(.bottom, 20)
            .padding(.horizontal, 16)
        }
        .onAppear(perform: viewModel.onAppear)
    }

    @ViewBuilder
    private var createdView: some View {
        VStack(spacing: 0) {
            Spacer()
                .frame(minHeight: 0)

            VStack(spacing: 20) {
                Assets.Visa.success.image
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 76, height: 76)

                VStack(spacing: 12) {
                    Text(Localization.tangempayCardDetailsChangePinSuccessTitle)
                        .style(Fonts.Bold.title1, color: Colors.Text.primary1)
                        .multilineTextAlignment(.center)

                    Text(Localization.tangempayCardDetailsChangePinSuccessDescription)
                        .style(Fonts.Regular.callout, color: Colors.Text.secondary)
                        .multilineTextAlignment(.center)
                        .frame(width: 265)
                }
            }

            Spacer()
                .frame(minHeight: 0)
            Spacer()
                .frame(minHeight: 0)

            MainButton(
                title: Localization.commonDone,
                action: viewModel.close
            )
            .padding(.bottom, 20)
            .padding(.horizontal, 16)
        }
    }
}
