//
//  TransferTypeContentView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemLocalization
import TangemUI

struct TransferTypeContentView: View {
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

private extension TransferTypeContentView {
    var sectionHeader: some View {
        // [REDACTED_TODO_COMMENT]
        Text("Type of transfer")
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

    func row(_ option: TransferTypeOption, showsDivider: Bool) -> some View {
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

private extension TransferTypeContentView {
    var continueButton: some View {
        TangemUI.Button(
            label: Localization.commonContinue,
            accessibilityLabel: nil,
            action: { action(.continueTap) }
        )
        .size(.x12)
        .styleType(.default)
        .horizontalLayout(.infinity)
        .disabled(state.selection == nil)
    }
}

// MARK: - Constants

private extension TransferTypeContentView {
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

extension TransferTypeContentView {
    struct State {
        let options: [TransferTypeOption]
        let selection: TransferTypeOption?
    }
}

// MARK: - Action

extension TransferTypeContentView {
    enum Action {
        case optionTap(TransferTypeOption)
        case continueTap
    }
}

// MARK: - Previews

@available(iOS 17.0, *)
#Preview("3rd-party account") {
    TransferTypeContentView(
        state: TransferTypeContentView.State(options: TransferTypeOption.allCases, selection: .thirdParty),
        action: { _ in }
    )
    .background(DesignSystem.Color.bgPrimary.ignoresSafeArea())
}
