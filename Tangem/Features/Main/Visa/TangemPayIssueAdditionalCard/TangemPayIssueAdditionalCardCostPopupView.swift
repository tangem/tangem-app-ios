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
            TangemPayPopupFeeRows(
                feeLabel: viewModel.feeLabel,
                feeValue: viewModel.feeText,
                balanceValue: viewModel.isInsufficientFunds ? viewModel.balanceText : nil
            )
        }
    }
}
