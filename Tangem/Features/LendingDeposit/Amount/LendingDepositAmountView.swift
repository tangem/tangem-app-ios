//
//  LendingDepositAmountView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI

struct LendingDepositAmountView: View {
    @ObservedObject var viewModel: LendingDepositAmountViewModel

    var body: some View {
        LendingDepositAmountContentView(
            field: viewModel.amountField,
            state: viewModel.state,
            action: viewModel.handle
        )
        .onAppear(perform: viewModel.onAppear)
    }
}
