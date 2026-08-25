//
//  MobileOnboardingImportICloudBackupView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI
import TangemAssets

struct MobileOnboardingImportICloudBackupView: View {
    @ObservedObject var viewModel: MobileOnboardingImportICloudBackupViewModel

    var body: some View {
        content
            .stepsFlowNavBar(title: viewModel.navigationTitle)
            .stepsFlowNavBar(leading: { navigationBackButton })
            .stepsFlowNavBar(backgroundColor: DesignSystem.Color.bgPrimary)
            .stepsFlow(isLoading: viewModel.isProcessing)
            .background(Appearance.backgroundColor)
            .onAppear(perform: viewModel.onAppear)
            .onDisappear {
                viewModel.onDisappear()
                UIApplication.shared.endEditing()
            }
    }
}

// MARK: - Subviews

private extension MobileOnboardingImportICloudBackupView {
    var navigationBackButton: some View {
        MobileOnboardingFlowNavBarAction.back(handler: viewModel.onBackTap).view()
    }

    var content: some View {
        ScrollView(.vertical) {
            VStack(alignment: .leading, spacing: .zero) {
                infoView

                inputView
                    .padding(.top, Layout.passwordTopPadding)

                validationView
                    .padding(.top, Layout.validationTopPadding)
            }
            .padding(.top, Layout.topPadding)
            .padding(.horizontal, Layout.horizontalPadding)
        }
        .safeAreaInset(edge: .bottom, spacing: .zero) {
            actions
                .padding(.vertical, Layout.actionsVerticalPadding)
                .background(Appearance.backgroundColor)
        }
    }

    var infoView: some View {
        let info = viewModel.info
        return InfoView(
            title: info.title,
            description: info.description
        )
    }

    var inputView: some View {
        InputView(
            title: viewModel.inputTitle,
            isSecured: viewModel.isInputSecured,
            text: $viewModel.inputText,
            isResponder: $viewModel.isInputResponder,
            onSecurityTap: viewModel.onInputSecurityTap
        )
    }

    var validationView: some View {
        let matching = viewModel.passwordMatching
        return PasswordMatchingView(
            description: matching.description,
            color: matching.color
        )
    }

    var actions: some View {
        ActionButton(
            title: viewModel.actionTitle,
            isLoading: viewModel.isProcessing,
            enabled: viewModel.isActionEnabled,
            action: viewModel.onActionTap
        )
        .padding(.horizontal, Layout.actionHorizontalPadding)
    }
}

// MARK: - Constants

private extension MobileOnboardingImportICloudBackupView {
    enum Appearance {
        static let backgroundColor = DesignSystem.Color.bgPrimary
    }

    enum Layout {
        static let topPadding: CGFloat = 12
        static let horizontalPadding: CGFloat = 24
        static let passwordTopPadding: CGFloat = 36
        static let validationTopPadding: CGFloat = 14
        static let actionHorizontalPadding: CGFloat = 16
        static let actionsVerticalPadding: CGFloat = 12
    }
}

// MARK: - InfoView

private struct InfoView: View {
    let title: String
    let description: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .style(DesignSystem.Font.headingSmallToken, color: DesignSystem.Color.textPrimary)

            Text(description)
                .style(DesignSystem.Font.subheadingMediumToken, color: DesignSystem.Color.textSecondary)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

// MARK: - InputView

private struct InputView: View {
    let title: String
    let isSecured: Bool

    @Binding var text: String
    @Binding var isResponder: Bool?

    let onSecurityTap: () -> Void

    private var inputSecurityImage: Image {
        isSecured
            ? DesignSystem.Icons.EyeCross.regular20.image
            : DesignSystem.Icons.Eye.regular20.image
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .style(DesignSystem.Font.captionMediumToken, color: DesignSystem.Color.textSecondary)

            HStack(spacing: 4) {
                CustomTextField(
                    text: $text,
                    isResponder: $isResponder,
                    actionButtonTapped: .constant(false),
                    isSecured: isSecured,
                    keyboard: .asciiCapable,
                    textColor: DesignSystem.Color.textPrimary.uiColor,
                    font: DesignSystem.Font.bodyMediumToken.uiFont,
                    placeholder: "",
                    isEnabled: true
                )

                Button(action: onSecurityTap) {
                    inputSecurityImage
                        .renderingMode(.template)
                        .foregroundStyle(DesignSystem.Color.iconSecondary)
                }
                .buttonStyle(.plain)
            }
        }
    }
}

// MARK: - PasswordMatchingView

private struct PasswordMatchingView: View {
    let description: String?
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Separator(
                height: .exact(1),
                color: color,
                axis: .horizontal
            )

            description.map {
                Text($0)
                    .style(DesignSystem.Font.captionMediumToken, color: color)
            }
        }
    }
}

// MARK: - ActionButton

private struct ActionButton: View {
    let title: String
    let isLoading: Bool
    let enabled: Bool
    let action: () -> Void

    var body: some View {
        TangemUI.Button(
            label: AttributedString(title),
            accessibilityLabel: nil,
            action: action
        )
        .styleType(.default)
        .horizontalLayout(.infinity)
        .size(.x12)
        .isLoading(isLoading)
        .disabled(!enabled)
    }
}
