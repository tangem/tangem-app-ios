//
//  TangemPayVirtualAccountOnboardingView.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI
import TangemAssets
import TangemLocalization
import TangemUIUtils
import TangemAccessibilityIdentifiers

struct TangemPayVirtualAccountOnboardingView: View {
    @ObservedObject var viewModel: TangemPayVirtualAccountInfoSheetViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                hero

                content
            }
        }
        .scrollIndicators(.hidden)
        .scrollBounceBehavior(.basedOnSize)
        .ignoresSafeArea(.container, edges: .top)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            footer
        }
        .overlay(alignment: .topTrailing) {
            closeButton
        }
        .background(DesignSystem.Color.bgPrimary.ignoresSafeArea())
        .animation(.contentFrameUpdate, value: viewModel.state)
        .alert(item: $viewModel.alert) { $0.alert }
    }

    private var closeButton: some View {
        TangemUI.Button(icon: DesignSystem.Icons.Cross.regular20, accessibilityLabel: nil, action: viewModel.close)
            .size(.x11)
            .styleType(.material(.glass))
            .disabled(viewModel.isLoading)
            .padding(.top, 8)
            .padding(.trailing, 16)
    }

    private var hero: some View {
        Assets.Visa.bankDetailsHero.image
            .resizable()
            .scaledToFit()
            .frame(width: Metrics.heroImageSize.width, height: Metrics.heroImageSize.height)
            .padding(.top, Metrics.heroImageTopPadding)
            .frame(maxWidth: .infinity)
            .background(alignment: .top) {
                LinearGradient(
                    colors: [DesignSystem.Color.bgStatusInfo, DesignSystem.Color.bgPrimary],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: Metrics.gradientHeight)
                .offset(y: Metrics.gradientVerticalOffset)
            }
    }

    private var content: some View {
        VStack(alignment: .leading, spacing: 8) {
            texts

            TangemPayVirtualAccountFeeListView(
                header: Localization.tangempayBankTransferOnboardingFeeHeader,
                state: viewModel.state,
                rowsHorizontalPadding: 0,
                reload: viewModel.reloadFees
            )

            footnote
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 24)
        .padding(.top, 40)
        .padding(.bottom, 24)
    }

    private var texts: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(Localization.tangempayBankTransferOnboardingTitle)
                .style(DesignSystem.Font.headingMediumToken, color: DesignSystem.Color.textPrimary)

            Text(Localization.tangempayBankTransferOnboardingDescription)
                .style(DesignSystem.Font.subheadingMediumToken, color: DesignSystem.Color.textSecondary)
        }
        .padding(.vertical, 12)
        .multilineTextAlignment(.leading)
        .fixedSize(horizontal: false, vertical: true)
    }

    private var footnote: some View {
        Group {
            Text(Localization.tangempayBankTransferSwiftWarning)
                + Text(verbatim: " ")
                + Text(Localization.moneyAccountOnboardingDisclaimer)
        }
        .style(DesignSystem.Font.subheadingMediumToken, color: DesignSystem.Color.textSecondary)
        .multilineTextAlignment(.leading)
        .padding(.vertical, 16)
        .fixedSize(horizontal: false, vertical: true)
    }

    private var footer: some View {
        VStack(spacing: 12) {
            if let agreementText = viewModel.agreementText {
                Text(agreementText)
                    .environment(\.openURL, OpenURLAction { url in
                        viewModel.openURL(url)
                        return .handled
                    })
                    .style(DesignSystem.Font.captionMediumToken, color: DesignSystem.Color.textSecondary)
                    .tint(DesignSystem.Color.textPrimary)
                    .multilineTextAlignment(.center)
            }

            TangemUI.Button(label: Localization.commonContinue, accessibilityLabel: nil, action: viewModel.showDetails)
                .styleType(.primary)
                .size(.x12)
                .horizontalLayout(.infinity)
                .loading(.spinner(if: viewModel.isLoading))
                .accessibilityIdentifier(TangemPayAccessibilityIdentifiers.virtualAccountOnboardingContinueButton)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background {
            Fade(position: .bottom)
                .variant(.hard)
                .blurred()
                .padding(.top, -Metrics.fadeOverhang)
                .ignoresSafeArea(edges: .bottom)
        }
    }
}

// MARK: - Metrics

private extension TangemPayVirtualAccountOnboardingView {
    enum Metrics {
        static let heroImageSize = CGSize(width: 356, height: 355)
        static let heroImageTopPadding: CGFloat = 90
        static let gradientHeight: CGFloat = 520
        static let gradientVerticalOffset: CGFloat = -100
        static let fadeOverhang: CGFloat = 16
    }
}

// MARK: - Animations

private extension Animation {
    static let contentFrameUpdate = Animation.curve(.easeInOutRefined, duration: 0.5)
}
