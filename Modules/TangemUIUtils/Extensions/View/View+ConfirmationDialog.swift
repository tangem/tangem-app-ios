//
//  View+ConfirmationDialog.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI

public extension View {
    /// Presents a confirmation dialog based on a `ConfirmationDialogViewModel` content.
    ///
    /// The dialog is automatically presented when the bound view model is non-`nil`, and dismissed when it becomes `nil`.
    ///
    /// - Parameter viewModel: A binding to an optional `ConfirmationDialogViewModel`.
    ///   When this value is non-`nil`, the confirmation dialog is presented. Setting it to `nil` dismisses the dialog.
    func confirmationDialog(viewModel: Binding<ConfirmationDialogViewModel?>) -> some View {
        confirmationDialog(
            viewModel.wrappedValue?.title ?? "",
            isPresented: Binding(
                get: { viewModel.wrappedValue != nil },
                set: { isPresented in
                    if !isPresented {
                        viewModel.wrappedValue = nil
                    }
                }
            ),
            titleVisibility: viewModel.wrappedValue?.titleVisibility ?? .automatic,
            presenting: viewModel.wrappedValue,
            actions: { viewModel in
                viewModel.actionsView
            },
            message: { viewModel in
                viewModel.messageView
            }
        )
    }
}

private extension ConfirmationDialogViewModel {
    var titleVisibility: Visibility {
        guard let title else {
            return .hidden
        }

        return title.isEmpty ? .hidden : .visible
    }

    var actionsView: some View {
        ForEach(buttons, id: \.self) { buttonViewModel in
            SwiftUI.Button(buttonViewModel.title, role: buttonViewModel.role?.toSwiftUIButtonRole, action: buttonViewModel.action)
        }
    }

    @ViewBuilder
    var messageView: some View {
        if let subtitle {
            Text(subtitle)
        }
    }
}

private extension ConfirmationDialogViewModel.ButtonRole {
    var toSwiftUIButtonRole: SwiftUI.ButtonRole {
        switch self {
        case .destructive: .destructive
        case .cancel: .cancel
        }
    }
}
