//
//  TransferInputContentView.swift
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

struct TransferInputContentView: View {
    @ObservedObject var amountFieldViewModel: DecimalNumberTextFieldViewModel

    let state: State
    let action: (Action) -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: Constants.sectionSpacing) {
                amountCard

                railRow

                errorBanner
            }
            .animation(.easeInOut, value: state.isErrorBannerVisible)
            .padding(.top, 12)
            .padding(.horizontal, Constants.horizontalPadding)
            .padding(.bottom, Constants.bottomPadding)
        }
        .scrollIndicators(.hidden)
        .scrollBounceBehavior(.basedOnSize)
        .safeAreaInset(edge: .bottom) {
            continueButton
                .padding(.vertical, 8)
                .padding(.horizontal, 16)
        }
    }
}

// MARK: - Amount Section

private extension TransferInputContentView {
    var amountCard: some View {
        VStack(spacing: .zero) {
            amountHeader

            amountSection

            Separator(height: .minimal, color: DesignSystem.Color.borderSecondary)
                .padding(.horizontal, 16)

            tokenRow
        }
        .padding(.top, Constants.cardVerticalPadding)
        .background(DesignSystem.Color.bgSecondary)
        .cornerRadiusContinuous(Constants.cardCornerRadius)
    }

    var amountHeader: some View {
        HStack(spacing: 4) {
            // [REDACTED_TODO_COMMENT]
            Text("From")

            Assets.Visa.accountAvatar.image
                .resizable()
                .scaledToFit()
                .frame(width: 16, height: 16)

            // [REDACTED_TODO_COMMENT]
            Text("Payment account")
        }
        .style(DesignSystem.Font.subheadingMediumToken, color: DesignSystem.Color.textTertiary)
    }

    var amountSection: some View {
        VStack(spacing: 8) {
            SendDecimalNumberTextField(viewModel: amountFieldViewModel)
                .prefixSuffixOptions(.prefix(text: AppConstants.usdSign, hasSpace: false))
                .appearance(.init(
                    font: DesignSystem.Font.displayMediumToken.font,
                    textColor: DesignSystem.Color.textPrimary,
                    placeholderColor: DesignSystem.Color.textTertiary
                ))
                .alignment(.center)

            Text(state.amountErrorMessage ?? "")
                .style(DesignSystem.Font.captionMediumToken, color: DesignSystem.Color.textStatusError)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, 38)
        .padding(.horizontal, Constants.cardHorizontalPadding)
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Token row

private extension TransferInputContentView {
    @ViewBuilder
    var tokenRow: some View {
        switch state.tokenRow {
        case .loading:
            skeletonRow

        case .token(let token):
            SwiftUI.Button {
                action(.tokenTap)
            } label: {
                Row(title: token.symbol, subtitle: token.subtitle)
                    .start {
                        TokenIconV2(tokenIconInfo: token.tokenIconInfo, size: .size40)
                    }
                    .end {
                        HStack(spacing: Constants.accessorySpacing) {
                            maxButton
                            chevron
                        }
                    }
            }

        case .unavailable:
            EmptyView()
        }
    }

    var skeletonRow: some View {
        HStack(spacing: Constants.accessorySpacing) {
            Shimmer()
                .frame(size: CGSize(bothDimensions: Constants.skeletonIconSide))
                .clipShape(.circle)

            VStack(alignment: .leading, spacing: Constants.skeletonLineSpacing) {
                Shimmer()
                    .variant(.text(style: .body, alignment: .leading))

                Shimmer()
                    .variant(.text(style: .caption, alignment: .leading))
            }

            Spacer(minLength: .zero)
        }
        .padding(Constants.cardHorizontalPadding)
    }

    var maxButton: some View {
        TangemUI.Button(
            // [REDACTED_TODO_COMMENT]
            label: "Max",
            accessibilityLabel: nil,
            action: { action(.maxTap) }
        )
        .size(.x8)
        .styleType(.secondary(.default))
    }

    var chevron: some View {
        DesignSystem.Icons.ChevronDown.regular20.image
            .renderingMode(.template)
            .foregroundStyle(DesignSystem.Color.iconSecondary)
    }
}

// MARK: - Rail row

private extension TransferInputContentView {
    @ViewBuilder
    var railRow: some View {
        if let rail = state.rail {
            SwiftUI.Button { action(.railTap) } label: {
                HStack(spacing: .zero) {
                    HStack(spacing: 12) {
                        rail.icon.image
                            .resizable()
                            .scaledToFit()
                            .frame(width: Constants.railIconSide, height: Constants.railIconSide)

                        Text(rail.title)
                            .style(DesignSystem.Font.bodyMediumToken, color: DesignSystem.Color.textPrimary)
                    }

                    Spacer()

                    HStack(spacing: Constants.accessorySpacing) {
                        HStack(spacing: 8) {
                            Badge(label: rail.etaText, accessibilityLabel: nil)

                            Text(rail.feeText)
                                .style(DesignSystem.Font.bodyMediumToken, color: DesignSystem.Color.textPrimary)
                        }

                        chevron
                    }
                }
                .padding(.vertical, 12)
                .padding(.horizontal, 16)
                .background(DesignSystem.Color.bgSecondary)
                .clipShape(Capsule(style: .circular))
            }
        }
    }
}

// MARK: - Error banner

private extension TransferInputContentView {
    @ViewBuilder
    var errorBanner: some View {
        if state.isErrorBannerVisible {
            TransferInputErrorBanner(action: { action(.retryTap) })
                .transition(.opacity)
        }
    }
}

// MARK: - Continue

private extension TransferInputContentView {
    var continueButton: some View {
        TangemUI.Button(
            label: Localization.commonContinue,
            accessibilityLabel: nil,
            action: { action(.continueTap) }
        )
        .size(.x12)
        .styleType(.default)
        .horizontalLayout(.infinity)
        .disabled(!state.isContinueEnabled)
    }
}

// MARK: - Constants

private extension TransferInputContentView {
    enum Constants {
        static let sectionSpacing: CGFloat = 8
        static let cardSpacing: CGFloat = 8
        static let amountSpacing: CGFloat = 52
        static let accessorySpacing: CGFloat = 12
        static let horizontalPadding: CGFloat = 16
        static let bottomPadding: CGFloat = 8
        static let cardHorizontalPadding: CGFloat = 16
        static let cardVerticalPadding: CGFloat = 16
        static let cardCornerRadius: CGFloat = 24
        static let skeletonIconSide: CGFloat = 40
        static let skeletonLineSpacing: CGFloat = 4
        static let railIconSide: CGFloat = 20
    }
}

// MARK: - State

extension TransferInputContentView {
    struct State {
        let tokenRow: TokenRow
        let rail: TransferInputRailItem?
        let amountErrorMessage: String?
        let isErrorBannerVisible: Bool
        let isContinueEnabled: Bool
    }
}

extension TransferInputContentView.State {
    enum TokenRow {
        case loading
        case token(TransferInputTokenItem)
        case unavailable
    }
}

// MARK: - Action

extension TransferInputContentView {
    enum Action {
        case tokenTap
        case railTap
        case maxTap
        case retryTap
        case continueTap
    }
}

// MARK: - Previews

#if DEBUG
private enum TransferInputPreview {
    static func make(amount: Decimal?, state: TransferInputContentView.State) -> some View {
        let fieldViewModel = DecimalNumberTextFieldViewModel(
            maximumFractionDigits: 2,
            locale: Locale(identifier: "en_US")
        )
        fieldViewModel.update(value: amount)

        return TransferInputContentView(
            amountFieldViewModel: fieldViewModel,
            state: state,
            action: { _ in }
        )
        .background(DesignSystem.Color.bgPrimary.ignoresSafeArea())
    }

    static func state(
        tokenRow: TransferInputContentView.State.TokenRow = .token(TransferInputTokenItem.previewList[0]),
        rail: TransferInputRailItem? = TransferInputRailItem.previewList.first,
        amountErrorMessage: String? = nil,
        isErrorBannerVisible: Bool = false,
        isContinueEnabled: Bool = false
    ) -> TransferInputContentView.State {
        TransferInputContentView.State(
            tokenRow: tokenRow,
            rail: rail,
            amountErrorMessage: amountErrorMessage,
            isErrorBannerVisible: isErrorBannerVisible,
            isContinueEnabled: isContinueEnabled
        )
    }
}

#Preview("Empty") {
    TransferInputPreview.make(amount: nil, state: TransferInputPreview.state())
}

#Preview("Valid amount") {
    TransferInputPreview.make(amount: 500, state: TransferInputPreview.state(isContinueEnabled: true))
}

#Preview("Out of range") {
    TransferInputPreview.make(
        amount: Decimal(string: "0.5"),
        state: TransferInputPreview.state(amountErrorMessage: "Please set amount from $1 to $10,000")
    )
}

#Preview("Loading") {
    TransferInputPreview.make(
        amount: nil,
        state: TransferInputPreview.state(tokenRow: .loading)
    )
}

#Preview("Options failed") {
    TransferInputPreview.make(
        amount: nil,
        state: TransferInputPreview.state(
            tokenRow: .unavailable,
            rail: nil,
            isErrorBannerVisible: true
        )
    )
}
#endif
