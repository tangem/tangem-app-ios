//
//  LendingConfirmContentView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemLocalization
import TangemUI
import TangemUIUtils

struct LendingConfirmContentView<Details: View>: View {
    let state: LendingConfirm.StateModel
    let action: (LendingConfirm.Action) -> Void
    @ViewBuilder let details: Details

    var body: some View {
        ScrollView {
            VStack(spacing: Constants.sectionSpacing) {
                header
                    .padding(.top, Constants.headerTopPadding)
                    .padding(.bottom, Constants.headerBottomPadding)

                details

                LendingFeeRow(
                    fee: state.fee,
                    canChangeFeeSpeed: state.canChangeFeeSpeed,
                    action: { action(.fee) },
                    retry: { action(.retryFee) }
                )
            }
            .padding(.horizontal, Constants.horizontalPadding)
            .disabled(state.isSubmitting)
        }
        .scrollIndicators(.hidden)
        .scrollBounceBehavior(.basedOnSize)
        .footer { footer }
        .environment(\.openURL, OpenURLAction { url in
            guard !state.isSubmitting else { return .handled }
            action(.openURL(url))
            return .handled
        })
        .background { DesignSystem.Color.bgPrimary.ignoresSafeArea() }
        .topNavigation(
            title: state.title,
            leading: state.isSubmitting ? .none : .automatic,
            close: state.isSubmitting ? .disabled : .enabled { action(.close) }
        )
        .interactiveDismissDisabled(state.isSubmitting)
    }
}

// MARK: - Header

private extension LendingConfirmContentView {
    var header: some View {
        VStack(spacing: Constants.headerSpacing) {
            HStack(spacing: -Constants.iconOverlap) {
                TokenIconV2(tokenIconInfo: state.tokenIconInfo, size: .size72)
                    .zIndex(1)

                Avatar(.asset(Assets.YieldModule.yieldModuleAaveLogo.image), size: .size72)
            }
            .padding(.bottom, Constants.iconsBottomPadding)

            Text(state.fiatAmount)
                .style(DesignSystem.Font.displayMediumToken, color: DesignSystem.Color.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(Constants.amountMinScale)

            Text(state.cryptoAmount)
                .style(DesignSystem.Font.captionMediumToken, color: DesignSystem.Color.textSecondary)
        }
    }
}

// MARK: - Footer

private extension LendingConfirmContentView {
    var footer: Footer {
        Footer(.signingButton(SigningActionButtonView(
            type: state.signingActionButtonType,
            title: state.submitTitle,
            isLoading: state.isSubmitting,
            isDisabled: !state.isSubmitEnabled,
            action: { action(.submit) }
        )))
        .caption(legalText)
        .showFade()
    }

    var legalText: AttributedString {
        let terms = Localization.commonTermsOfUse
        let privacy = Localization.commonPrivacyPolicy
        // [REDACTED_TODO_COMMENT]
        var text = AttributedString("By continuing you agree with the \(terms) and \(privacy)")
        link(terms, to: AaveLinks.termsOfService, in: &text)
        link(privacy, to: AaveLinks.privacyPolicy, in: &text)
        return text
    }

    func link(_ title: String, to url: URL?, in text: inout AttributedString) {
        guard let url, let range = text.range(of: title) else {
            return
        }

        text[range].foregroundColor = DesignSystem.Color.textPrimary
        text[range].link = url
    }
}

// MARK: - State Model

enum LendingConfirm {
    struct StateModel {
        let title: String
        let tokenIconInfo: TokenIconInfo
        let fiatAmount: String
        let cryptoAmount: String
        let fee: LendingFee
        let canChangeFeeSpeed: Bool
        let signingActionButtonType: SigningActionButtonViewType
        let submitTitle: String
        let isSubmitEnabled: Bool
        let isSubmitting: Bool
    }

    enum Action {
        case close
        case fee
        case retryFee
        case openURL(URL)
        case submit
    }
}

// MARK: - Constants

private enum Constants {
    static let sectionSpacing: CGFloat = 8
    static let horizontalPadding: CGFloat = 16
    static let headerTopPadding: CGFloat = 32
    static let headerBottomPadding: CGFloat = 32
    static let headerSpacing: CGFloat = 4
    static let iconOverlap: CGFloat = 16
    static let iconsBottomPadding: CGFloat = 20
    static let amountMinScale: CGFloat = 0.5
}
