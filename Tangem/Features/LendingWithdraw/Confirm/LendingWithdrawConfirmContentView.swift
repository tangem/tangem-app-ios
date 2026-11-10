//
//  LendingWithdrawConfirmContentView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI

struct LendingWithdrawConfirmContentView: View {
    let state: StateModel
    let action: (Action) -> Void

    var body: some View {
        LendingConfirmContentView(state: confirmState, action: handle) {
            LendingNoticeBanner(text: LendingWithdrawText.notice)
                .padding(.bottom, Constants.noticeBottomPadding)
        }
    }

    private var confirmState: LendingConfirm.StateModel {
        LendingConfirm.StateModel(
            title: LendingWithdrawText.title,
            tokenIconInfo: state.tokenIconInfo,
            fiatAmount: state.fiatAmount,
            cryptoAmount: state.cryptoAmount,
            fee: state.fee,
            canChangeFeeSpeed: state.canChangeFeeSpeed,
            signingActionButtonType: state.signingActionButtonType,
            submitTitle: LendingWithdrawText.withdraw,
            isSubmitEnabled: state.isWithdrawEnabled,
            isSubmitting: state.isWithdrawing
        )
    }

    private func handle(_ confirmAction: LendingConfirm.Action) {
        switch confirmAction {
        case .close: action(.close)
        case .fee: action(.fee)
        case .retryFee: action(.retryFee)
        case .openURL(let url): action(.openURL(url))
        case .submit: action(.withdraw)
        }
    }
}

// MARK: - Constants

private extension LendingWithdrawConfirmContentView {
    enum Constants {
        static let noticeBottomPadding: CGFloat = 28
    }
}

// MARK: - State Model

extension LendingWithdrawConfirmContentView {
    struct StateModel {
        let tokenIconInfo: TokenIconInfo
        var fiatAmount: String
        var cryptoAmount: String
        var fee: LendingFee
        var canChangeFeeSpeed: Bool
        let signingActionButtonType: SigningActionButtonViewType
        var isWithdrawEnabled: Bool
        var isWithdrawing: Bool
    }

    enum Action {
        case close
        case fee
        case retryFee
        case openURL(URL)
        case withdraw
    }
}
