//
//  LendingDepositConfirmContentView.swift
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

struct LendingDepositConfirmContentView: View {
    let state: StateModel
    let action: (Action) -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: Constants.sectionSpacing) {
                header
                    .padding(.top, Constants.headerTopPadding)
                    .padding(.bottom, Constants.headerBottomPadding)

                ratesCard

                LendingDepositFeeRow(fee: state.fee, canChangeFeeSpeed: state.canChangeFeeSpeed, action: { action(.fee) })
            }
            .padding(.horizontal, Constants.horizontalPadding)
            .disabled(state.isDepositing)
        }
        .scrollIndicators(.hidden)
        .scrollBounceBehavior(.basedOnSize)
        .footer { footer }
        .environment(\.openURL, OpenURLAction { url in
            action(.openURL(url))
            return .handled
        })
        .background { DesignSystem.Color.bgPrimary.ignoresSafeArea() }
        .topNavigation(
            // [REDACTED_TODO_COMMENT]
            title: "Lending on Aave",
            leading: state.isDepositing ? .none : .automatic,
            close: state.isDepositing ? .disabled : .enabled { action(.close) }
        )
        .interactiveDismissDisabled(state.isDepositing)
    }
}

// MARK: - Header

private extension LendingDepositConfirmContentView {
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

// MARK: - Rates

private extension LendingDepositConfirmContentView {
    var ratesCard: some View {
        VStack(spacing: .zero) {
            // [REDACTED_TODO_COMMENT]
            rateRow(title: "Current APY", value: state.currentApy, showsDivider: true)
            rateRow(title: "Performance fee", value: state.performanceFee, showsDivider: true)
            rateRow(title: "Projected earnings", value: state.projectedEarnings, showsDivider: false)
        }
        .background(DesignSystem.Color.bgSecondary)
        .cornerRadiusContinuous(Constants.cornerRadius)
    }

    func rateRow(title: String, value: String, showsDivider: Bool) -> some View {
        Row(title: title, value: value)
            .overrideTextColors(RowOverrideTextColors(title: DesignSystem.Color.textSecondary))
            .titleLineLimit(nil)
            .valueLineLimit(nil)
            .showDivider(showsDivider)
    }
}

// MARK: - Footer

private extension LendingDepositConfirmContentView {
    var footer: Footer {
        Footer(.signingButton(SigningActionButtonView(
            type: state.signingActionButtonType,
            // [REDACTED_TODO_COMMENT]
            title: "Deposit",
            isLoading: state.isDepositing,
            isDisabled: !state.isDepositEnabled,
            action: { action(.deposit) }
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

extension LendingDepositConfirmContentView {
    struct StateModel {
        let tokenIconInfo: TokenIconInfo
        var fiatAmount: String
        var cryptoAmount: String
        let currentApy: String
        let performanceFee: String
        var projectedEarnings: String
        var fee: LendingDepositFee
        var canChangeFeeSpeed: Bool
        let signingActionButtonType: SigningActionButtonViewType
        var isDepositEnabled: Bool
        var isDepositing: Bool
    }

    enum Action {
        case close
        case fee
        case openURL(URL)
        case deposit
    }
}

// MARK: - Constants

private extension LendingDepositConfirmContentView {
    enum Constants {
        static let sectionSpacing: CGFloat = 8
        static let horizontalPadding: CGFloat = 16
        static let headerTopPadding: CGFloat = 32
        static let headerBottomPadding: CGFloat = 32
        static let headerSpacing: CGFloat = 4
        static let iconOverlap: CGFloat = 16
        static let iconsBottomPadding: CGFloat = 20
        static let amountMinScale: CGFloat = 0.5
        static let cornerRadius: CGFloat = 24
    }
}
