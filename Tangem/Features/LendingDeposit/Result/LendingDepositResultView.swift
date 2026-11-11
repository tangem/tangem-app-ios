//
//  LendingDepositResultView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI

struct LendingDepositResultView: View {
    let viewModel: LendingDepositResultViewModel

    var body: some View {
        LendingDepositResultContentView(state: viewModel.state, action: viewModel.handle)
    }
}
