//
//  LendingDepositConfirmView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUIUtils

struct LendingDepositConfirmView: View {
    @ObservedObject var viewModel: LendingDepositConfirmViewModel

    var body: some View {
        LendingDepositConfirmContentView(state: viewModel.state, action: viewModel.handle)
            .bindAlert($viewModel.alert)
    }
}
