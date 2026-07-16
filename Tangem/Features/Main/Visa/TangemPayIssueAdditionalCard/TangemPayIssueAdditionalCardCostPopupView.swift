//
//  TangemPayIssueAdditionalCardCostPopupView.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI

struct TangemPayIssueAdditionalCardCostPopupView: View {
    @ObservedObject var viewModel: TangemPayIssueAdditionalCardCostPopupViewModel

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
                        buttonAction: viewModel.openAddFunds
                    )
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                }
            }
        }
    }
}
