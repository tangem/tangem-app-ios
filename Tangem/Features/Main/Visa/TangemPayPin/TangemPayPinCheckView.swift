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
import TangemUIUtils
import TangemAssets

struct TangemPayPinCheckView: View {
    @ObservedObject var viewModel: TangemPayPinCheckViewModel

    var body: some View {
        if FeatureProvider.isAvailable(.tangemPaySpendRedesign) {
            redesignedBody
        } else {
            legacyBody
        }
    }

    private var legacyBody: some View {
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
                            ActivityIndicatorView(color: UIColor(Color.Tangem.Graphic.Neutral.tertiary))

                        case .loaded(let pin):
                            OnboardingPinStackView(
                                maxDigits: viewModel.pinCodeLength,
                                isDisabled: true,
                                pinText: .constant(pin)
                            )
                            .pinStackDigitBackground(Colors.Background.action)
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
            Button(action: viewModel.close, label: {
                Assets.Glyphs.cross20ButtonNew.image
                    .resizable()
                    .renderingMode(.template)
                    .frame(width: 24, height: 24)
                    .padding(4)
                    .foregroundStyle(Color.Tangem.Fill.Neutral.secondary)
                    .background {
                        Capsule()
                            .fill(Colors.Button.secondary)
                    }
            })
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
                    style: .secondary,
                    action: viewModel.changePin
                )
                .padding(.bottom, 16)
                .padding(.horizontal, 16)
            }
        }
        .background(Color.Tangem.Surface.level3)
    }
}

// MARK: - Redesigned

private extension TangemPayPinCheckView {
    var redesignedBody: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                Spacer(minLength: 0)

                TangemButtonV2(
                    icon: DesignSystem.Icons.Cross.regular20,
                    accessibilityLabel: Localization.commonClose,
                    action: viewModel.close
                )
                .size(.x11)
                .styleType(.material(.glass))
            }
            .padding(.top, DesignSystem.Tokens.Spacing.s200)
            .padding(.horizontal, DesignSystem.Tokens.Spacing.s200)

            VStack(spacing: DesignSystem.Tokens.Spacing.s400) {
                VStack(spacing: DesignSystem.Tokens.Spacing.s100) {
                    Text(Localization.tangempayYourPinCode)
                        .style(DesignSystem.Tokens.Font.Heading.small, color: DesignSystem.Tokens.Theme.Text.primary)

                    Text(Localization.tangempayComeBackIfForgetPin)
                        .style(DesignSystem.Tokens.Font.Subheading.medium, color: DesignSystem.Tokens.Theme.Text.secondary)
                }
                .multilineTextAlignment(.center)

                redesignedPinContent
            }
            .padding(.top, DesignSystem.Tokens.Spacing.s400)
            .padding(.horizontal, DesignSystem.Tokens.Spacing.s200)

            redesignedChangePinButton
        }
        .frame(maxWidth: .infinity)
        .floatingSheetConfiguration { configuration in
            configuration.sheetBackgroundColor = DesignSystem.Tokens.Theme.Bg.secondary
            configuration.backgroundInteractionBehavior = .tapToDismiss
        }
    }

    var redesignedPinContent: some View {
        Color.clear
            .frame(height: DesignSystem.Tokens.Size.s800)
            .overlay {
                switch viewModel.state {
                case .loading:
                    TangemLoader()
                        .loaderSize(.size24)

                case .loaded(let pin):
                    TangemPayPinStackView(
                        pinText: .constant(pin),
                        length: viewModel.pinCodeLength,
                        isDisabled: true
                    )
                }
            }
    }

    var redesignedChangePinButton: some View {
        TangemButtonV2(
            label: AttributedString(Localization.tangempayChangePinCode),
            accessibilityLabel: Localization.tangempayChangePinCode,
            action: viewModel.changePin
        )
        .size(.x12)
        .styleType(.default)
        .horizontalLayout(.infinity)
        .disabled(!viewModel.isPinLoaded)
        .padding(.top, DesignSystem.Tokens.Spacing.s400)
        .padding(.horizontal, DesignSystem.Tokens.Spacing.s200)
        .padding(.bottom, DesignSystem.Tokens.Spacing.s200)
    }
}
