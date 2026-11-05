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
import TangemUIUtils

struct TangemPayMoneyAccountView: View {
    @StateObject private var viewModel: TangemPayMoneyAccountViewModel

    init(viewModel: @autoclosure @escaping () -> TangemPayMoneyAccountViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel())
    }

    var body: some View {
        TangemPayMoneyAccountContentView(
            state: viewModel.stateModel,
            refreshScrollState: viewModel.refreshScrollState,
            action: viewModel.handleAction
        )
        .tangemPayMoneyAccountToolbar(
            menuSections: viewModel.menuSections,
            onMenuItemSelected: { viewModel.handleAction(.selectMenuItem($0)) }
        )
        .alert(item: $viewModel.alert) { $0.alert }
        .task {
            await viewModel.loadState()
        }
    }
}
