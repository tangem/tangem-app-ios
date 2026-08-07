//
//  TangemPayFeePopupView.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAccessibilityIdentifiers

struct TangemPayFeePopupView<ViewModel: TangemPayFeePopupViewModel>: View {
    @ObservedObject var viewModel: ViewModel

    var body: some View {
        TangemPayPopupView(viewModel: viewModel) {
            VStack(spacing: 0) {
                TangemPayPopupFeeRows(
                    feeLabel: viewModel.feeLabel,
                    feeValue: viewModel.feeText,
                    balanceValue: nil
                )

                if viewModel.isInsufficientFunds {
                    TangemPayInsufficientFundsBanner(
                        title: viewModel.insufficientFundsBannerTitle,
                        message: viewModel.insufficientFundsBannerMessage,
                        buttonTitle: viewModel.addFundsButtonTitle,
                        buttonAccessibilityIdentifier: TangemPayAccessibilityIdentifiers.reissueSheetAddFundsButton,
                        buttonAction: viewModel.openAddFunds
                    )
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                }
            }
        }
    }
}
