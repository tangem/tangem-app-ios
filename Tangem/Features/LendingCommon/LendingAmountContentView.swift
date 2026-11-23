//
//  LendingAmountContentView.swift
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
import struct TangemAccounts.AccountIconView

struct LendingAmountContentView: View {
    @ObservedObject var field: AmountInputFieldModel

    let state: StateModel
    let action: (Action) -> Void

    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @FocusState private var isAmountFocused: Bool

    var body: some View {
        ScrollView {
            VStack(spacing: Constants.sectionSpacing) {
                amountCard
                feeRow

                if let notice = state.notice {
                    LendingNoticeBanner(text: notice)
                }
            }
            .padding(.horizontal, Constants.horizontalPadding)
        }
        .scrollIndicators(.hidden)
        .scrollBounceBehavior(.basedOnSize)
        .legacyFooter {
            VStack(spacing: .zero) {
                if isAmountFocused {
                    shareChips
                }

                Footer(.buttons(primary: submitButton))
                    .disabled(!state.isSubmitEnabled)
            }
            .background { footerFade }
        }
        .background { DesignSystem.Color.bgPrimary.ignoresSafeArea() }
        .onAppear(perform: focusAmount)
    }
}

// MARK: - Amount card

private extension LendingAmountContentView {
    var amountCard: some View {
        VStack(spacing: .zero) {
            if let header = state.header {
                headerView(header)
                    .style(DesignSystem.Font.captionMediumToken, color: DesignSystem.Color.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, Constants.cardPadding)
                    .padding(.top, Constants.cardPadding)
                    .padding(.bottom, Constants.headerBottomPadding)
            }

            VStack(spacing: Constants.amountSpacing) {
                textField
                bottomInfo
            }
            .padding(.vertical, Constants.amountVerticalPadding)
            .padding(.horizontal, Constants.cardPadding)

            Separator(height: .minimal, color: DesignSystem.Color.borderSecondary)
                .padding(.horizontal, Constants.cardPadding)

            sourceRow
        }
        .background(DesignSystem.Color.bgSecondary)
        .cornerRadiusContinuous(Constants.cornerRadius)
    }

    @ViewBuilder
    func headerView(_ header: Header) -> some View {
        switch header {
        case .wallet(let name):
            Text(Localization.commonFromWalletName(name))
        case .account(let name, let icon):
            HStack(spacing: Constants.headerSpacing) {
                Text(Localization.commonFrom)

                AccountIconView(data: icon)
                    .settings(.smallSized)
                    .accessibilityHidden(true)

                Text(name)
            }
            .accessibilityElement(children: .combine)
        }
    }

    @ViewBuilder
    var textField: some View {
        switch field.amountType {
        case .crypto:
            makeTextField(viewModel: field.cryptoTextFieldViewModel, options: field.cryptoTextFieldOptions)
        case .fiat:
            makeTextField(viewModel: field.fiatTextFieldViewModel, options: field.fiatTextFieldOptions)
        }
    }

    func makeTextField(
        viewModel: DecimalNumberTextFieldViewModel,
        options: SendDecimalNumberTextField.PrefixSuffixOptions
    ) -> some View {
        SendDecimalNumberTextField(viewModel: viewModel)
            .prefixSuffixOptions(options)
            .appearance(.init(
                font: DesignSystem.Font.displayMediumToken.font,
                textColor: DesignSystem.Color.textPrimary,
                placeholderColor: DesignSystem.Color.textTertiary
            ))
            .alignment(.center)
            .minTextScale(Constants.amountMinTextScale)
            .focused($isAmountFocused)
    }

    @ViewBuilder
    var bottomInfo: some View {
        switch field.bottomInfoText {
        case .error(let text):
            HStack(spacing: Constants.errorSpacing) {
                if field.possibleToConvertToFiat {
                    alternativeToggle

                    Text("·")
                        .style(DesignSystem.Font.captionMediumToken, color: DesignSystem.Color.textSecondary)
                        .accessibilityHidden(true)
                }

                Text(text)
                    .style(DesignSystem.Font.captionMediumToken, color: DesignSystem.Color.textStatusError)
                    .multilineTextAlignment(.center)
            }
        case .info(let text):
            Text(text)
                .style(DesignSystem.Font.captionMediumToken, color: DesignSystem.Color.textStatusWarning)
                .multilineTextAlignment(.center)
        case .none where field.possibleToConvertToFiat:
            alternativeToggle
        case .none:
            Text(" ")
                .style(DesignSystem.Font.captionMediumToken, color: DesignSystem.Color.textSecondary)
                .hidden()
        }
    }

    var alternativeToggle: some View {
        SwiftUI.Button {
            field.amountType = field.amountType == .crypto ? .fiat : .crypto
        } label: {
            HStack(spacing: Constants.alternativeSpacing) {
                Text(field.alternativeAmount)
                    .style(DesignSystem.Font.captionMediumToken, color: DesignSystem.Color.textSecondary)
                    .lineLimit(1)

                DesignSystem.Icons.ArrowRightLeft.regular16.image
                    .renderingMode(.template)
                    .foregroundStyle(DesignSystem.Color.iconBrand)
                    .accessibilityHidden(true)
            }
        }
        // [REDACTED_TODO_COMMENT]
        .accessibilityHint("Switches the amount between crypto and fiat")
    }

    var sourceRow: some View {
        Row(title: state.source.title, subtitle: state.source.subtitle)
            .start {
                TokenIconV2(tokenIconInfo: state.source.tokenIconInfo, size: .size40)
            }
            .end {
                TangemUI.Button(
                    label: Localization.sendMaxAmount,
                    accessibilityLabel: nil,
                    action: { action(.max) }
                )
                .size(.x8)
                .styleType(.secondary(.default))
            }
    }
}

// MARK: - Fee row

private extension LendingAmountContentView {
    var feeRow: some View {
        LendingFeeRow(fee: state.fee, canChangeFeeSpeed: state.canChangeFeeSpeed, action: openFeeSpeed, retry: { action(.retryFee) })
    }

    func openFeeSpeed() {
        isAmountFocused = false
        action(.fee)
    }
}

// MARK: - Footer

private extension LendingAmountContentView {
    var footerFade: some View {
        Fade(position: .bottom)
            .variant(.hard)
            .blurred(!reduceTransparency)
            .padding(.top, -Constants.footerFadeOverhang)
            .ignoresSafeArea(edges: .bottom)
    }

    var shareChips: some View {
        HStack(spacing: Constants.chipSpacing) {
            ForEach(Constants.sharePercents, id: \.self) { percent in
                TangemUI.Button(
                    label: "\(percent)%",
                    accessibilityLabel: nil,
                    action: { action(.share(percent)) }
                )
                .size(.x8)
                .styleType(.secondary(.default))
                .horizontalLayout(.infinity)
            }

            TangemUI.Button(
                icon: DesignSystem.Icons.KeyboardDown.regular20,
                accessibilityLabel: Localization.commonHide,
                action: { isAmountFocused = false }
            )
            .size(.x8)
            .styleType(.secondary(.default))
        }
        .padding(.horizontal, Constants.horizontalPadding)
        .padding(.top, Constants.chipsTopPadding)
    }

    var submitButton: TangemUI.Button {
        TangemUI.Button(
            label: state.submitTitle,
            accessibilityLabel: nil,
            action: {
                isAmountFocused = false
                action(.submit)
            }
        )
        .styleType(.primary)
    }

    func focusAmount() {
        guard !isAmountFocused else { return }

        Task {
            try? await Task.sleep(for: .seconds(Constants.keyboardAppearDelay))
            isAmountFocused = true
        }
    }
}

// MARK: - State Model

extension LendingAmountContentView {
    struct StateModel {
        let header: Header?
        var source: Source
        var fee: LendingFee
        var canChangeFeeSpeed: Bool
        let notice: String?
        let submitTitle: String
        var isSubmitEnabled: Bool
    }

    struct Source {
        let tokenIconInfo: TokenIconInfo
        let title: String
        var subtitle: String
    }

    enum Header {
        case account(name: String, icon: AccountIconView.ViewData)
        case wallet(name: String)
    }

    enum Action {
        case max
        case share(Int)
        case fee
        case retryFee
        case submit
    }
}

// MARK: - Constants

private extension LendingAmountContentView {
    enum Constants {
        static let sharePercents = [25, 50, 75, 100]
        static let sectionSpacing: CGFloat = 8
        static let horizontalPadding: CGFloat = 16
        static let cardPadding: CGFloat = 16
        static let cornerRadius: CGFloat = 24
        static let headerSpacing: CGFloat = 4
        static let headerBottomPadding: CGFloat = 4
        static let amountSpacing: CGFloat = 8
        static let amountVerticalPadding: CGFloat = 40
        static let amountMinTextScale: CGFloat = 0.5
        static let alternativeSpacing: CGFloat = 2
        static let errorSpacing: CGFloat = 6
        static let chipSpacing: CGFloat = 4
        static let chipsTopPadding: CGFloat = 8
        static let footerFadeOverhang: CGFloat = 16
        static let keyboardAppearDelay: TimeInterval = 0.5
    }
}
