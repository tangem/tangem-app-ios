//
//  TangemPayReissuePopupView.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI

struct TangemPayReissuePopupView: View {
    @ObservedObject var viewModel: TangemPayReissueSheetViewModel

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
