//
//  LendingWithdrawAmountView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI

struct LendingWithdrawAmountView: View {
    @ObservedObject var viewModel: LendingWithdrawAmountViewModel

    var body: some View {
        LendingWithdrawAmountContentView(
            field: viewModel.amountField,
            state: viewModel.state,
            action: viewModel.handle
        )
        .onAppear(perform: viewModel.onAppear)
    }
}
