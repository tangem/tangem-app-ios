//
//  MobileOnboardingICloudBackupView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI
import TangemAssets

struct MobileOnboardingICloudBackupView: View {
    typealias ViewModel = MobileOnboardingICloudBackupViewModel

    @ObservedObject var viewModel: ViewModel

    var body: some View {
        content
            .stepsFlowNavBar(title: viewModel.navigationTitle)
            .stepsFlowNavBar(
                leading: { viewModel.leadingNavBarAction?.view() },
                trailing: viewModel.trailingNavBarAction.view
            )
            .stepsFlowNavBar(backgroundColor: Appearance.backgroundColor)
            .stepsFlow(isLoading: viewModel.isProcessing)
            .background(Appearance.backgroundColor)
            .onDisappear {
                viewModel.onDisappear()
                UIApplication.shared.endEditing()
            }
    }
}

// MARK: - Subviews

private extension MobileOnboardingICloudBackupView {
    var content: some View {
        ScrollView(.vertical) {
            VStack(alignment: .leading, spacing: .zero) {
                InfoView(
                    title: viewModel.infoTitle,
                    description: viewModel.infoDescription
                )

                PasswordView(
                    title: viewModel.passwordTitle,
                    isSecured: viewModel.isPasswordSecured,
                    text: $viewModel.passwordText,
                    isResponder: $viewModel.isPasswordResponder,
                    onSecurityTap: viewModel.onPasswordSecurityTap
                )
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

    @ViewBuilder
    var validationView: some View {
        switch viewModel.state {
        case .setPassword:
            setPasswordValidationView(viewModel.passwordStrengthInfo)
                .onAppear(perform: viewModel.onSetPasswordAppear)
        case .confirmPassword:
            confirmPasswordValidationView(viewModel.passwordMatching)
                .onAppear(perform: viewModel.onConfirmPasswordAppear)
        }
    }

    func setPasswordValidationView(_ info: ViewModel.PasswordStrengthInfo) -> some View {
        PasswordStrengthView(
            title: info.title,
            description: info.description,
            progress: info.progress,
            color: info.color
        )
    }

    func confirmPasswordValidationView(_ matching: ViewModel.PasswordMatching) -> some View {
        PasswordMatchingView(
            description: matching.description,
            color: matching.color
        )
    }

    var actions: some View {
        VStack(alignment: .leading, spacing: Layout.actionsSpacing) {
            if viewModel.isPasswordWarningVisible {
                passwordWarningView
                    .padding(.horizontal, Layout.passwordWarningHorizontalPadding)
            }

            ActionButton(
                title: viewModel.actionTitle,
                isLoading: viewModel.isProcessing,
                enabled: viewModel.isActionEnabled,
                action: viewModel.onActionTap
            )
            .padding(.horizontal, Layout.actionHorizontalPadding)
        }
    }

    var passwordWarningView: some View {
        HStack(alignment: .top, spacing: 14) {
            TangemUI.Checkbox(isOn: $viewModel.isPasswordWarningAccepted)
                .expandsHitArea(false)

            Text(viewModel.passwordWarningTitle)
                .style(DesignSystem.Font.captionMediumToken, color: DesignSystem.Color.textPrimary)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
        }
        .contentShape(.rect)
        .onTapGesture(perform: viewModel.onPasswordWarningTap)
    }
}

// MARK: - Constants

private extension MobileOnboardingICloudBackupView {
    enum Appearance {
        static let backgroundColor = DesignSystem.Color.bgPrimary
    }

    enum Layout {
        static let topPadding: CGFloat = 12
        static let horizontalPadding: CGFloat = 24
        static let passwordTopPadding: CGFloat = 36
        static let validationTopPadding: CGFloat = 14
        static let validationSpacing: CGFloat = 8
        static let passwordWarningHorizontalPadding: CGFloat = 24
        static let actionHorizontalPadding: CGFloat = 16
        static let actionsSpacing: CGFloat = 20
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

// MARK: - PasswordView

private struct PasswordView: View {
    let title: String
    let isSecured: Bool

    @Binding var text: String
    @Binding var isResponder: Bool?

    let onSecurityTap: () -> Void

    private var passwordSecurityImage: Image {
        isSecured
            ? DesignSystem.Icons.EyeCross.regular20.image
            : DesignSystem.Icons.Eye.regular20.image
    }

    private static let fontToken = DesignSystem.Font.bodyMediumToken

    @ScaledMetric(relativeTo: fontToken.relativeTo)
    private var fieldHeight = fontToken.lineHeight

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
                    font: Self.fontToken.uiFont,
                    placeholder: "",
                    isEnabled: true
                )
                .frame(height: fieldHeight)

                Button(action: onSecurityTap) {
                    passwordSecurityImage
                        .renderingMode(.template)
                        .foregroundStyle(DesignSystem.Color.iconSecondary)
                }
                .buttonStyle(.plain)
            }
        }
    }
}

// MARK: - PasswordStrengthView

private struct PasswordStrengthView: View {
    let title: String
    let description: String
    let progress: Double
    let color: Color

    private var needsProgress: Bool { progress > 0 }

    private let progressLineWidth: CGFloat = 2

    var body: some View {
        VStack(alignment: .leading, spacing: .zero) {
            Separator(
                height: .exact(1),
                color: DesignSystem.Color.borderBrand,
                axis: .horizontal
            )

            HStack(spacing: 4) {
                if needsProgress {
                    progressView(progress)
                        .frame(size: CGSize(bothDimensions: 14))
                        .animation(.default, value: progress)
                }

                Text(title)
                    .style(DesignSystem.Font.subheadingMediumToken, color: color)
            }
            .padding(.top, 12)

            Text(description)
                .style(DesignSystem.Font.captionMediumToken, color: DesignSystem.Color.textSecondary)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 8)
        }
    }

    private func progressView(_ progress: Double) -> some View {
        ZStack {
            Circle()
                .strokeBorder(DesignSystem.Color.borderTertiary, lineWidth: progressLineWidth)

            ProgressArc(progress: progress)
                .strokeBorder(color, style: StrokeStyle(lineWidth: progressLineWidth, lineCap: .round))
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
