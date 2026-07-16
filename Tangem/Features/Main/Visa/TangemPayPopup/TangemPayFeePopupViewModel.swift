//
//  TangemPayFeePopupViewModel.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import TangemUI
import TangemLocalization

@MainActor
protocol TangemPayFeePopupViewModel: TangemPayPopupViewModel {
    var feeLabel: String { get }
    var feeText: String { get }
    var isInsufficientFunds: Bool { get }
    var insufficientFundsBannerTitle: String { get }
    var insufficientFundsBannerMessage: String { get }
    var addFundsButtonTitle: String { get }

    func openAddFunds()
}

extension TangemPayFeePopupViewModel {
    var secondaryButton: MainButton.Settings? {
        isInsufficientFunds
            ? nil
            : MainButton.Settings(
                title: Localization.commonCancel,
                style: .secondary,
                size: .default,
                action: dismiss
            )
    }
}
