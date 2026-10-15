//
//  TangemPayWaitlistView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUI
import TangemUIUtils

struct TangemPayWaitlistView: View {
    @StateObject private var viewModel: TangemPayWaitlistViewModel
    @FocusState private var focusedField: TangemPayFormField.ID?

    init(viewModel: @autoclosure @escaping () -> TangemPayWaitlistViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel())
    }

    var body: some View {
        TangemPayWaitlistContentView(
            field: $viewModel.field,
            state: viewModel.contentState,
            action: viewModel.handle
        )
        .background { DesignSystem.Color.bgPrimary.ignoresSafeArea() }
        .alert(item: $viewModel.alert) { $0.alert }
    }
}
