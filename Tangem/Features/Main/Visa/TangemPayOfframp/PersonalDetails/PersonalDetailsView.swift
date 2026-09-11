//
//  PersonalDetailsView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUI

struct PersonalDetailsView: View {
    @StateObject private var viewModel: PersonalDetailsViewModel
    @FocusState private var focusedField: PersonalDetailsField.ID?

    init(viewModel: @autoclosure @escaping () -> PersonalDetailsViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel())
    }

    var body: some View {
        PersonalDetailsContentView(
            fields: $viewModel.fields,
            focused: $focusedField,
            state: viewModel.contentState,
            action: handle
        )
        .background { DesignSystem.Color.bgPrimary.ignoresSafeArea() }
        .topNavigation(
            title: viewModel.title,
            subtitle: viewModel.stepSubtitle,
            onClose: viewModel.onCloseTap
        )
        .onChange(of: focusedField, perform: viewModel.focusedFieldDidChange(to:))
    }
}

// MARK: - Actions

private extension PersonalDetailsView {
    func handle(_ action: PersonalDetailsContentView.Action) {
        switch action {
        case .fieldChanged(let id):
            viewModel.fieldDidChange(id)

        case .focusPrevious:
            moveFocus(to: viewModel.fieldBefore(focusedField))

        case .focusNext:
            moveFocus(to: viewModel.fieldAfter(focusedField))

        case .dismissKeyboard:
            focusedField = nil

        case .continueTap:
            focusedField = nil
            viewModel.submit()
        }
    }

    func moveFocus(to id: PersonalDetailsField.ID?) {
        guard let id else { return }

        focusedField = id
    }
}
