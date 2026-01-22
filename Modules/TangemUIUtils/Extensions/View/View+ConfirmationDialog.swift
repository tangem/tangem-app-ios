//
//  View+ConfirmationDialog.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI

public extension View {
    /// Presents a confirmation dialog configured by a ``ConfirmationDialogViewModel``.
    ///
    /// The dialog is presented for non-`nil` `viewModel.wrappedValue` value.
    /// When the dialog is dismissed, the binding is set to `nil`.
    ///
    /// - Note: If you have a property of type ``ConfirmationDialogViewModel``
    /// consider using ``confirmationDialog(viewModel:dismissAction:)`` overload instead.
    ///
    /// - Parameter viewModel: A binding to an optional dialog view model.
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

    /// Presents a confirmation dialog configured by a ``ConfirmationDialogViewModel``.
    ///
    /// The dialog is presented for non-`nil` `viewModel` value.
    /// When the dialog is dismissed, `onDismiss` callback is called.
    ///
    /// - Note: If you have a property of type ``Binding<ConfirmationDialogViewModel?>``
    /// consider using ``confirmationDialog(viewModel:)`` overload instead.
    ///
    /// - Parameters:
    ///   - viewModel: An optional dialog view model that provides the dialog’s title, message, and actions.
    ///   - onDismiss: Called when the dialog is dismissed.
    func confirmationDialog(viewModel: ConfirmationDialogViewModel?, onDismiss: @escaping () -> Void) -> some View {
        confirmationDialog(
            viewModel?.title ?? "",
            isPresented: Binding(
                get: { viewModel != nil },
                set: { isPresented in
                    if !isPresented {
                        onDismiss()
                    }
                }
            ),
            titleVisibility: viewModel?.titleVisibility ?? .automatic,
            presenting: viewModel,
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
