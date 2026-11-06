//
//  EarnWithdrawalResultView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI

struct EarnWithdrawalResultView: View {
    let viewModel: EarnWithdrawalResultViewModel

    var body: some View {
        EarnWithdrawalResultContentView(state: viewModel.state, action: viewModel.handle)
    }
}
