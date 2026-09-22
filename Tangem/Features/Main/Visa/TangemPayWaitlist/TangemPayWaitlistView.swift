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
            focused: $focusedField,
            state: viewModel.contentState,
            action: handle
        )
        .background { DesignSystem.Color.bgPrimary.ignoresSafeArea() }
        .onChange(of: focusedField, perform: viewModel.focusedFieldDidChange(to:))
        .alert(item: $viewModel.alert) { $0.alert }
    }
}

// MARK: - Actions

private extension TangemPayWaitlistView {
    func handle(_ action: TangemPayWaitlistContentView.Action) {
        if case .saveTap = action {
            focusedField = nil
        }

        viewModel.handle(action)
    }
}
