//
//  TangemPayWaitlistContentView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemFoundation
import TangemLocalization
import TangemUI
import TangemUIUtils

struct TangemPayWaitlistContentView: View {
    @Binding var field: TangemPayFormField
    let state: State
    let action: (Action) -> Void

    @FocusState private var emailFocused: TangemPayFormField.ID?

    var body: some View {
        content
            .offrampBottomBar { bottomBar }
            .environment(\.openURL, OpenURLAction { url in
                action(.privacyPolicyTap(url))
                return .handled
            })
    }
}

// MARK: - Content

private extension TangemPayWaitlistContentView {
    var content: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Constants.headerToFieldSpacing) {
                header

                TangemPayFormFieldView(field: $field, focused: $emailFocused)
                    .disabled(state.isSaving)
                    .onChange(of: field.text) { _ in
                        action(.emailChanged)
                    }
                    .onAppear {
                        guard emailFocused == nil else { return }

                        Task {
                            try? await Task.sleep(for: .seconds(0.5))
                            emailFocused = .email
                        }
                    }
            }
            .padding(.horizontal, Constants.horizontalPadding)
            .padding(.top, Constants.topPadding)
        }
        .scrollIndicators(.hidden)
        .scrollBounceBehavior(.basedOnSize)
        .scrollDismissesKeyboard(.interactively)
    }

    var header: some View {
        VStack(alignment: .leading, spacing: Constants.titleToSubtitleSpacing) {
            Text(Localization.tangempayWaitlistTitle.trimmed())
                .style(DesignSystem.Font.headingMediumToken, color: DesignSystem.Color.textPrimary)

            Text(Localization.tangempayWaitlistDescription)
                .style(DesignSystem.Font.subheadingMediumToken, color: DesignSystem.Color.textSecondary)
        }
        .multilineTextAlignment(.leading)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Bottom bar

private extension TangemPayWaitlistContentView {
    var bottomBar: some View {
        VStack(spacing: Constants.bottomBarSpacing) {
            marketingConsent

            saveButton
        }
        .lockedGeometry()
    }

    var marketingConsent: some View {
        HStack(alignment: .center, spacing: Constants.consentSpacing) {
            Checkbox(value: state.isMarketingConsentOn ? .checked : .unchecked) {
                action(.marketingConsentTap)
            }
            .expandsHitArea(false)
            .expandingHitArea(by: Constants.checkboxHitAreaInset)

            Text(marketingConsentText)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .disabled(state.isSaving)
    }

    var marketingConsentText: AttributedString {
        let privacyPolicy = Localization.commonPrivacyPolicy
        var string = AttributedString(Localization.tangempayWaitlistMarketingConsent(privacyPolicy))
        string.setFontStyle(DesignSystem.Font.captionMediumToken)
        string.foregroundColor = DesignSystem.Color.textSecondary

        if let range = string.range(of: privacyPolicy) {
            string[range].foregroundColor = DesignSystem.Color.textPrimary
            string[range].link = AppConstants.tangemPayPrivacyPolicyURL
        }

        return string
    }

    var saveButton: some View {
        TangemUI.Button(
            label: Localization.commonSave,
            accessibilityLabel: nil,
            action: {
                emailFocused = nil
                action(.saveTap)
            }
        )
        .size(.x12)
        .styleType(.primary)
        .horizontalLayout(.infinity)
        .loading(.spinner(if: state.isSaving))
        .disabled(!state.isSaveEnabled)
    }
}

// MARK: - Constants

private extension TangemPayWaitlistContentView {
    enum Constants {
        static let horizontalPadding: CGFloat = 24
        static let topPadding: CGFloat = 12
        static let titleToSubtitleSpacing: CGFloat = 8
        static let headerToFieldSpacing: CGFloat = 32
        static let bottomBarSpacing: CGFloat = 16
        static let consentSpacing: CGFloat = 12
        static let checkboxHitAreaInset: CGFloat = 10
    }
}

// MARK: - Geometry

private extension View {
    @ViewBuilder
    func lockedGeometry() -> some View {
        if #available(iOS 17.0, *) {
            geometryGroup()
        } else {
            self
        }
    }
}

// MARK: - State

extension TangemPayWaitlistContentView {
    struct State {
        let isMarketingConsentOn: Bool
        let isSaveEnabled: Bool
        let isSaving: Bool
    }
}

// MARK: - Action

extension TangemPayWaitlistContentView {
    enum Action {
        case emailChanged
        case marketingConsentTap
        case privacyPolicyTap(URL)
        case saveTap
    }
}

// MARK: - Previews

@available(iOS 17.0, *)
#Preview("Empty") {
    @Previewable @State var field = TangemPayFormField(
        id: .email,
        title: Localization.tangempayOrderDataEmail,
        placeholder: Localization.tangempayWaitlistEmailPlaceholder
    )

    TangemPayWaitlistContentView(
        field: $field,
        state: TangemPayWaitlistContentView.State(
            isMarketingConsentOn: false,
            isSaveEnabled: false,
            isSaving: false
        ),
        action: { _ in }
    )
    .background(DesignSystem.Color.bgPrimary.ignoresSafeArea())
}

@available(iOS 17.0, *)
#Preview("Invalid email") {
    @Previewable @State var field = TangemPayFormField(
        id: .email,
        title: Localization.tangempayOrderDataEmail,
        placeholder: Localization.tangempayWaitlistEmailPlaceholder,
        text: "satoshi.nakamoto@tangem",
        error: .invalidEmail
    )

    TangemPayWaitlistContentView(
        field: $field,
        state: TangemPayWaitlistContentView.State(
            isMarketingConsentOn: false,
            isSaveEnabled: false,
            isSaving: false
        ),
        action: { _ in }
    )
    .background(DesignSystem.Color.bgPrimary.ignoresSafeArea())
}

@available(iOS 17.0, *)
#Preview("Valid email") {
    @Previewable @State var field = TangemPayFormField(
        id: .email,
        title: Localization.tangempayOrderDataEmail,
        placeholder: Localization.tangempayWaitlistEmailPlaceholder,
        text: "satoshi.nakamoto@tangem.com"
    )

    @Previewable @FocusState var focused: TangemPayFormField.ID?

    TangemPayWaitlistContentView(
        field: $field,
        state: TangemPayWaitlistContentView.State(
            isMarketingConsentOn: true,
            isSaveEnabled: true,
            isSaving: false
        ),
        action: { _ in }
    )
    .background(DesignSystem.Color.bgPrimary.ignoresSafeArea())
}

@available(iOS 17.0, *)
#Preview("Saving") {
    @Previewable @State var field = TangemPayFormField(
        id: .email,
        title: Localization.tangempayOrderDataEmail,
        placeholder: Localization.tangempayWaitlistEmailPlaceholder,
        text: "satoshi.nakamoto@tangem.com"
    )

    TangemPayWaitlistContentView(
        field: $field,
        state: TangemPayWaitlistContentView.State(
            isMarketingConsentOn: false,
            isSaveEnabled: true,
            isSaving: true
        ),
        action: { _ in }
    )
    .background(DesignSystem.Color.bgPrimary.ignoresSafeArea())
}
