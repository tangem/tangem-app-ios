//
//  TangemPayMoneyAccountView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemLocalization
import TangemUI

struct TangemPayMoneyAccountView: View {
    @StateObject private var viewModel: TangemPayMoneyAccountViewModel

    init(viewModel: @autoclosure @escaping () -> TangemPayMoneyAccountViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel())
    }

    var body: some View {
        TangemPayMoneyAccountContentView(
            state: viewModel.stateModel,
            action: viewModel.handleAction
        )
    }
}
