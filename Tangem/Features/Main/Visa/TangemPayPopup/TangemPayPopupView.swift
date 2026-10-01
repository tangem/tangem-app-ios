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
import TangemAccessibilityIdentifiers

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
        content
    }
}

extension TangemPayPopupView where AdditionalContent == EmptyView {
    init(viewModel: ViewModel) {
        self.init(viewModel: viewModel, additionalContent: { EmptyView() })
    }
}

private extension TangemPayPopupView {
    var content: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                Spacer(minLength: 0)
                TangemUI.Button(icon: DesignSystem.Icons.Cross.regular20, accessibilityLabel: Localization.commonClose, action: viewModel.dismiss)
                    .size(.x11)
                    .styleType(.material(.glass))
                    .accessibilityIdentifier(TangemPayAccessibilityIdentifiers.popupCloseButton)
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
            .accessibilityIdentifier(TangemPayAccessibilityIdentifiers.popupIcon)
    }

    var texts: some View {
        VStack(spacing: 8) {
            Text(viewModel.title)
                .font(token: DesignSystem.Font.headingSmallToken)
                .foregroundStyle(DesignSystem.Color.textPrimary)
                .fixedSize(horizontal: false, vertical: true)

            Text(viewModel.description)
                .environment(\.openURL, OpenURLAction(handler: { link in
                    viewModel.onHyperLinkTap(link)
                    return .handled
                }))
                .font(token: DesignSystem.Font.subheadingMediumToken)
                .foregroundStyle(DesignSystem.Color.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .multilineTextAlignment(.center)
    }

    var buttons: some View {
        VStack(spacing: 8) {
            if let secondaryButton = viewModel.secondaryButton {
                button(secondaryButton, style: .secondary(.default))
                    .accessibilityIdentifier(TangemPayAccessibilityIdentifiers.popupSecondaryButton)
            }

            button(viewModel.primaryButton, style: .default)
                .accessibilityIdentifier(viewModel.primaryButtonAccessibilityIdentifier)
        }
    }

    func button(_ settings: MainButton.Settings, style: TangemUI.Button.StyleType) -> some View {
        TangemUI.Button(
            label: AttributedString(settings.title),
            accessibilityLabel: settings.title,
            action: settings.action
        )
        .size(.x12)
        .styleType(style)
        .horizontalLayout(.infinity)
        .loading(.spinner(if: settings.isLoading))
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
