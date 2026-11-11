//
//  LendingDepositAmountContentView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemLocalization
import TangemUI

struct LendingDepositAmountContentView: View {
    @ObservedObject var field: AmountInputFieldModel

    let state: LendingAmountContentView.StateModel
    let action: (Action) -> Void

    var body: some View {
        LendingAmountContentView(field: field, state: state, action: handle)
            .topNavigation(
                // [REDACTED_TODO_COMMENT]
                title: "Deposit to Lending on Aave",
                leading: .custom(TopNavigation.Action(
                    icon: DesignSystem.Icons.Info.regular20,
                    accessibilityLabel: Localization.commonLearnMore,
                    action: { action(.info) }
                )),
                close: .enabled { action(.close) }
            )
    }

    private func handle(_ amountAction: LendingAmountContentView.Action) {
        switch amountAction {
        case .share(let percent): action(.share(percent))
        case .fee: action(.fee)
        case .retryFee: action(.retryFee)
        case .submit: action(.deposit)
        }
    }
}

// MARK: - Action

extension LendingDepositAmountContentView {
    enum Action {
        case info
        case close
        case share(Int)
        case fee
        case retryFee
        case deposit
    }
}
