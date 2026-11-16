//
//  LendingDepositConfirmContentView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUI
import TangemUIUtils

struct LendingDepositConfirmContentView: View {
    let state: StateModel
    let action: (Action) -> Void

    var body: some View {
        LendingConfirmContentView(state: confirmState, action: handle) {
            ratesCard
        }
    }

    private var confirmState: LendingConfirm.StateModel {
        LendingConfirm.StateModel(
            // [REDACTED_TODO_COMMENT]
            title: "Lending on Aave",
            tokenIconInfo: state.tokenIconInfo,
            fiatAmount: state.fiatAmount,
            cryptoAmount: state.cryptoAmount,
            fee: state.fee,
            canChangeFeeSpeed: state.canChangeFeeSpeed,
            signingActionButtonType: state.signingActionButtonType,
            submitTitle: "Deposit",
            isSubmitEnabled: state.isDepositEnabled,
            isSubmitting: state.isDepositing
        )
    }

    private func handle(_ confirmAction: LendingConfirm.Action) {
        switch confirmAction {
        case .close: action(.close)
        case .fee: action(.fee)
        case .retryFee: action(.retryFee)
        case .openURL(let url): action(.openURL(url))
        case .submit: action(.deposit)
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

// MARK: - State Model

extension LendingDepositConfirmContentView {
    struct StateModel {
        let tokenIconInfo: TokenIconInfo
        var fiatAmount: String
        var cryptoAmount: String
        let currentApy: String
        let performanceFee: String
        var projectedEarnings: String
        var fee: LendingFee
        var canChangeFeeSpeed: Bool
        let signingActionButtonType: SigningActionButtonViewType
        var isDepositEnabled: Bool
        var isDepositing: Bool
    }

    enum Action {
        case close
        case fee
        case retryFee
        case openURL(URL)
        case deposit
    }
}

// MARK: - Constants

private extension LendingDepositConfirmContentView {
    enum Constants {
        static let cornerRadius: CGFloat = 24
    }
}
