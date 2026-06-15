//
//  TangemPayPopupView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI
import TangemAssets
import TangemLocalization

struct TangemPayPopupView<AdditionalContent: View>: View {
    let viewModel: any TangemPayPopupViewModel
    private let additionalContent: AdditionalContent

    init(
        viewModel: any TangemPayPopupViewModel,
        @ViewBuilder additionalContent: () -> AdditionalContent
    ) {
        self.viewModel = viewModel
        self.additionalContent = additionalContent()
    }

    var body: some View {
        if FeatureProvider.isAvailable(.tangemPaySpendRedesign) {
            redesignedBody
        } else {
            legacyBody
        }
    }
}

extension TangemPayPopupView where AdditionalContent == EmptyView {
    init(viewModel: any TangemPayPopupViewModel) {
        self.init(viewModel: viewModel, additionalContent: { EmptyView() })
    }
}

private extension TangemPayPopupView {
    var redesignedBody: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                Spacer(minLength: 0)
                TangemButtonV2(icon: DesignSystem.Icons.Cross.regular20, accessibilityLabel: Localization.commonClose, action: viewModel.dismiss)
                    .size(.x11)
                    .styleType(.material(.glass))
            }
            .padding(.top, DesignSystem.Tokens.Spacing.s200)
            .padding(.bottom, DesignSystem.Tokens.Spacing.s200)
            .padding(.horizontal, DesignSystem.Tokens.Spacing.s200)

            VStack(spacing: DesignSystem.Tokens.Spacing.s400) {
                icon

                texts
                    .padding(.horizontal, DesignSystem.Tokens.Spacing.s400)
            }
            .padding(.horizontal, DesignSystem.Tokens.Spacing.s200)
            .padding(.vertical, DesignSystem.Tokens.Spacing.s400)
            .frame(maxWidth: .infinity)

            additionalContent

            buttons
                .padding(DesignSystem.Tokens.Spacing.s200)
        }
        .floatingSheetConfiguration { config in
            config.backgroundInteractionBehavior = .tapToDismiss
            config.sheetBackgroundColor = DesignSystem.Tokens.Theme.Bg.secondary
        }
    }

    var icon: some View {
        viewModel.icon
            .renderingMode(.template)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: DesignSystem.Tokens.Size.s350, height: DesignSystem.Tokens.Size.s350)
            .foregroundStyle(viewModel.iconStyle.iconColor)
            .frame(width: DesignSystem.Tokens.Size.s1000, height: DesignSystem.Tokens.Size.s1000)
            .background(viewModel.iconStyle.circleColor, in: Circle())
    }

    var texts: some View {
        VStack(spacing: DesignSystem.Tokens.Spacing.s100) {
            Text(viewModel.title)
                .font(DesignSystem.Tokens.Font.Heading.small)
                .foregroundStyle(DesignSystem.Tokens.Theme.Text.primary)
                .fixedSize(horizontal: false, vertical: true)

            Text(viewModel.description)
                .environment(\.openURL, OpenURLAction(handler: { link in
                    viewModel.onHyperLinkTap(link)
                    return .handled
                }))
                .font(DesignSystem.Tokens.Font.Subheading.medium)
                .foregroundStyle(DesignSystem.Tokens.Theme.Text.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .multilineTextAlignment(.center)
    }

    var buttons: some View {
        VStack(spacing: DesignSystem.Tokens.Spacing.s100) {
            if let secondaryButton = viewModel.secondaryButton {
                button(secondaryButton, style: .secondary)
            }

            button(viewModel.primaryButton, style: .default)
                .accessibilityIdentifier(viewModel.primaryButtonAccessibilityIdentifier)
        }
    }

    func button(_ settings: MainButton.Settings, style: TangemButtonV2.StyleType) -> some View {
        TangemButtonV2(
            label: AttributedString(settings.title),
            accessibilityLabel: settings.title,
            action: settings.action
        )
        .size(.x12)
        .styleType(style)
        .horizontalLayout(.infinity)
        .isLoading(settings.isLoading)
        .disabled(settings.isDisabled)
    }
}

private extension TangemPayPopupIconStyle {
    var circleColor: Color {
        switch self {
        case .info: DesignSystem.Tokens.Theme.Bg.Status.infoSubtle
        case .warning: DesignSystem.Tokens.Theme.Bg.Status.warningSubtle
        case .error: DesignSystem.Tokens.Theme.Bg.Status.errorSubtle
        }
    }

    var iconColor: Color {
        switch self {
        case .info: DesignSystem.Tokens.Theme.Icon.Status.info
        case .warning: DesignSystem.Tokens.Theme.Icon.Status.warning
        case .error: DesignSystem.Tokens.Theme.Icon.Status.error
        }
    }
}

private extension TangemPayPopupView {
    var legacyBody: some View {
        VStack(spacing: 24) {
            VStack(spacing: 24) {
                viewModel.icon
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(size: .init(bothDimensions: 56))
                    .padding(.top, 64)

                VStack(spacing: 12) {
                    Text(viewModel.title)
                        .style(
                            Fonts.Bold.title3,
                            color: Colors.Text.primary1
                        )
                        .fixedSize(horizontal: false, vertical: true)

                    Text(viewModel.description)
                        .environment(\.openURL, OpenURLAction(handler: { link in
                            viewModel.onHyperLinkTap(link)
                            return .handled
                        }))
                        .style(
                            Fonts.Regular.subheadline,
                            color: Colors.Text.secondary
                        )
                        .fixedSize(horizontal: false, vertical: true)
                }
                .multilineTextAlignment(.center)
                .padding(.horizontal, 16)

                additionalContent

                VStack(spacing: 8) {
                    MainButton(settings: viewModel.primaryButton)
                        .accessibilityIdentifier(viewModel.primaryButtonAccessibilityIdentifier)

                    if let secondarySettings = viewModel.secondaryButton {
                        MainButton(settings: secondarySettings)
                    }
                }
            }
            .overlay(alignment: .topTrailing) {
                NavigationBarButton
                    .close(action: viewModel.dismiss)
                    .padding(.top, 8)
            }
            .floatingSheetConfiguration { config in
                config.backgroundInteractionBehavior = .tapToDismiss
            }
            .padding(.bottom, 12)
            .padding(.horizontal, 16)
            .frame(maxWidth: .infinity)
        }
    }
}
