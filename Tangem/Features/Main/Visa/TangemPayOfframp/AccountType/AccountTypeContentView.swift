//
//  AccountTypeContentView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemLocalization
import TangemUI

struct AccountTypeContentView: View {
    let state: State
    let action: (Action) -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: .zero) {
                sectionHeader
                    .padding(.vertical, Constants.headerVerticalSpacing)
                    .padding(.horizontal, Constants.headerHorizontalSpacing)

                optionsCard
            }
            .padding(.top, Constants.topPadding)
            .padding(.horizontal, Constants.horizontalPadding)
            .padding(.bottom, Constants.bottomPadding)
        }
        .scrollIndicators(.hidden)
        .scrollBounceBehavior(.basedOnSize)
        .offrampBottomBar { continueButton }
    }
}

// MARK: - Options

private extension AccountTypeContentView {
    var sectionHeader: some View {
        Text(Localization.tangempayWithdrawBankAccountTypeTitle)
            .style(DesignSystem.Font.captionMediumToken, color: DesignSystem.Color.textSecondary)
    }

    var optionsCard: some View {
        VStack(spacing: .zero) {
            ForEach(state.options) { option in
                row(option, showsDivider: option != state.options.last)
            }
        }
        .background(DesignSystem.Color.bgSecondary)
        .cornerRadiusContinuous(Constants.cardCornerRadius)
    }

    func row(_ option: AccountTypeOption, showsDivider: Bool) -> some View {
        Row(title: option.title)
            .end {
                TangemUI.Checkmark(
                    checked: option == state.selection,
                    action: {}
                )
                .expandsHitArea(false)
                .allowsHitTesting(false)
            }
            .showDivider(showsDivider)
            .onTap { action(.optionTap(option)) }
    }
}

// MARK: - Continue

private extension AccountTypeContentView {
    var continueButton: some View {
        TangemUI.Button(
            label: Localization.commonContinue,
            accessibilityLabel: nil,
            action: { action(.continueTap) }
        )
        .size(.x12)
        .styleType(.primary)
        .horizontalLayout(.infinity)
        .disabled(state.selection == nil)
    }
}

// MARK: - Constants

private extension AccountTypeContentView {
    enum Constants {
        static let headerHorizontalSpacing: CGFloat = 16
        static let headerVerticalSpacing: CGFloat = 8
        static let topPadding: CGFloat = 12
        static let horizontalPadding: CGFloat = 16
        static let bottomPadding: CGFloat = 8
        static let cardCornerRadius: CGFloat = 24
    }
}

// MARK: - State

extension AccountTypeContentView {
    struct State {
        let options: [AccountTypeOption]
        let selection: AccountTypeOption?
    }
}

// MARK: - Action

extension AccountTypeContentView {
    enum Action {
        case optionTap(AccountTypeOption)
        case continueTap
    }
}

// MARK: - Previews

@available(iOS 17.0, *)
#Preview {
    @Previewable @State var selected: AccountTypeOption? = nil

    AccountTypeContentView(
        state: AccountTypeContentView.State(
            options: AccountTypeOption.allCases,
            selection: selected
        ),
        action: {
            if case .optionTap(let option) = $0 {
                selected = option
            }
        }
    )
    .background(DesignSystem.Color.bgPrimary.ignoresSafeArea())
}
