//
//  LendingWithdrawConfirmView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUIUtils

struct LendingWithdrawConfirmView: View {
    @ObservedObject var viewModel: LendingWithdrawConfirmViewModel

    var body: some View {
        LendingWithdrawConfirmContentView(state: viewModel.state, action: viewModel.handle)
            .bindAlert($viewModel.alert)
    }
}
