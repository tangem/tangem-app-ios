//
//  TangemPayWithdrawInProgressSheetView.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI
import TangemAssets
import TangemLocalization

struct TangemPayWithdrawInProgressSheetView: View {
    let viewModel: TangemPayWithdrawInProgressSheetViewModel

    var body: some View {
        TangemPayPopupView(
            viewModel: TangemPayWithdrawInProgressPopupViewModel(onClose: viewModel.close)
        )
    }
}
