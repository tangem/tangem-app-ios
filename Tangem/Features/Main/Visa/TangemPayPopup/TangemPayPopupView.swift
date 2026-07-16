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

struct TangemPayPopupView<ViewModel: TangemPayPopupViewModel, AdditionalContent: View>: View {
    @ObservedObject var viewModel: ViewModel
    private let additionalContent: AdditionalContent

    init(
        viewModel: ViewModel,
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
    init(viewModel: ViewModel) {
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
            .padding(.top, 16)
            .padding(.bottom, 16)
            .padding(.horizontal, 16)

            VStack(spacing: 32) {
                icon

                texts
                    .padding(.horizontal, 32)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 32)
            .frame(maxWidth: .infinity)

            additionalContent

            buttons
                .padding(16)
        }
        .floatingSheetConfiguration { config in
            config.backgroundInteractionBehavior = .tapToDismiss
            config.sheetBackgroundColor = DesignSystem.Color.bgSecondary
        }
    }

    var icon: some View {
        viewModel.icon
            .renderingMode(.template)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: 28, height: 28)
            .foregroundStyle(viewModel.iconStyle.iconColor)
            .frame(width: 80, height: 80)
            .background(viewModel.iconStyle.circleColor, in: Circle())
    }

    var texts: some View {
        VStack(spacing: 8) {
            Text(viewModel.title)
                .font(DesignSystem.Font.headingSmallToken)
                .foregroundStyle(DesignSystem.Color.textPrimary)
                .fixedSize(horizontal: false, vertical: true)

            Text(viewModel.description)
                .environment(\.openURL, OpenURLAction(handler: { link in
                    viewModel.onHyperLinkTap(link)
                    return .handled
                }))
                .font(DesignSystem.Font.subheadingMediumToken)
                .foregroundStyle(DesignSystem.Color.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .multilineTextAlignment(.center)
    }

    var buttons: some View {
        VStack(spacing: 8) {
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
        case .info: DesignSystem.Color.bgStatusInfoSubtle
        case .warning: DesignSystem.Color.bgStatusWarningSubtle
        case .error: DesignSystem.Color.bgStatusErrorSubtle
        }
    }

    var iconColor: Color {
        switch self {
        case .info: DesignSystem.Color.iconStatusInfo
        case .warning: DesignSystem.Color.iconStatusWarning
        case .error: DesignSystem.Color.iconStatusError
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
