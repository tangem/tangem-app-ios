//
//  TangemPayMaximumCardsIssuedSheetView.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI

struct TangemPayMaximumCardsIssuedSheetView: View {
    let viewModel: TangemPayMaximumCardsIssuedSheetViewModel

    var body: some View {
        TangemPayPopupView(
            viewModel: TangemPayMaximumCardsIssuedPopupViewModel(onClose: viewModel.dismiss)
        )
    }
}
