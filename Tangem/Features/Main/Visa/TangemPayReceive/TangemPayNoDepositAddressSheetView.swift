//
//  TangemPayNoDepositAddressSheetView.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI

struct TangemPayNoDepositAddressSheetView: View {
    let viewModel: TangemPayNoDepositAddressSheetViewModel

    var body: some View {
        TangemPayPopupView(
            viewModel: TangemPayNoDepositAddressPopupViewModel(onClose: viewModel.close)
        )
    }
}
