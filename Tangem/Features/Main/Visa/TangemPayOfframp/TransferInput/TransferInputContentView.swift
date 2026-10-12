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

    let state: StateModel
    let action: (Action) -> Void

    @FocusState private var isAmountFocused: Bool
    @State private var isContinuing = false

    var body: some View {
        ScrollView {
            VStack(spacing: Constants.sectionSpacing) {
                amountCard

                railRow
            }
            .padding(.top, 12)
            .padding(.horizontal, Constants.horizontalPadding)
            .padding(.bottom, Constants.bottomPadding)
        }
        .scrollIndicators(.hidden)
        .scrollBounceBehavior(.basedOnSize)
        .offrampBottomBar { continueButton }
        .onAppear {
            isContinuing = false
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
            Text(Localization.commonFrom)

            Assets.Visa.accountAvatar.image
                .resizable()
                .scaledToFit()
                .frame(width: 16, height: 16)

            Text(Localization.tangempayPaymentAccount)
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
                .focused($isAmountFocused)
                .task {
                    guard !isAmountFocused else { return }

                    try? await Task.sleep(for: .seconds(Constants.keyboardAnimationDelay))
                    isAmountFocused = true
                }

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
        if let token = state.token {
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
        }
    }

    var maxButton: some View {
        TangemUI.Button(
            label: Localization.sendMaxAmount,
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
            if state.isRailSelectable {
                SwiftUI.Button { action(.railTap) } label: {
                    railContent(rail, showsChevron: true)
                }
            } else {
                railContent(rail, showsChevron: false)
            }
        }
    }

    func railContent(_ rail: TransferInputRailItem, showsChevron: Bool) -> some View {
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

                if showsChevron {
                    chevron
                }
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(DesignSystem.Color.bgSecondary)
        .clipShape(Capsule(style: .circular))
    }
}

// MARK: - Continue

private extension TransferInputContentView {
    var continueButton: some View {
        TangemUI.Button(
            label: Localization.commonContinue,
            accessibilityLabel: nil,
            action: continueAction
        )
        .size(.x12)
        .styleType(.primary)
        .horizontalLayout(.infinity)
        .disabled(!state.isContinueEnabled || isContinuing)
    }

    func continueAction() {
        isContinuing = true
        isAmountFocused = false

        Task {
            try? await Task.sleep(for: .seconds(Constants.keyboardAnimationDelay))
            action(.continueTap)
        }
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
        static let railIconSide: CGFloat = 20
        static let keyboardAnimationDelay: TimeInterval = 0.33
    }
}

// MARK: - State Model

extension TransferInputContentView {
    struct StateModel {
        let token: TransferInputTokenItem?
        let rail: TransferInputRailItem?
        let isRailSelectable: Bool
        let amountErrorMessage: String?
        let isContinueEnabled: Bool
    }
}

// MARK: - Action

extension TransferInputContentView {
    enum Action {
        case tokenTap
        case railTap
        case maxTap
        case continueTap
    }
}

// MARK: - Previews

#if DEBUG
private enum TransferInputPreview {
    static func make(amount: Decimal?, state: TransferInputContentView.StateModel) -> some View {
        let fieldViewModel = DecimalNumberTextFieldViewModel(maximumFractionDigits: 2)
        fieldViewModel.update(value: amount)

        return TransferInputContentView(
            amountFieldViewModel: fieldViewModel,
            state: state,
            action: { _ in }
        )
        .background(DesignSystem.Color.bgPrimary.ignoresSafeArea())
    }

    static func state(
        token: TransferInputTokenItem? = TransferInputTokenItem.previewList[0],
        rail: TransferInputRailItem? = TransferInputRailItem.previewList.first,
        isRailSelectable: Bool = true,
        amountErrorMessage: String? = nil,
        isContinueEnabled: Bool = false
    ) -> TransferInputContentView.StateModel {
        TransferInputContentView.StateModel(
            token: token,
            rail: rail,
            isRailSelectable: isRailSelectable,
            amountErrorMessage: amountErrorMessage,
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

#Preview("Saved account") {
    TransferInputPreview.make(
        amount: 500,
        state: TransferInputPreview.state(
            rail: TransferInputRailItem.previewList[1],
            isRailSelectable: false,
            isContinueEnabled: true
        )
    )
}

#Preview("Out of range") {
    TransferInputPreview.make(
        amount: Decimal(string: "0.5"),
        state: TransferInputPreview.state(amountErrorMessage: "Please set amount from $1 to $10,000")
    )
}
#endif
