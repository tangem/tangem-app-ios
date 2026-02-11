//
//  ConfirmationDialogViewModel.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import struct TangemFoundation.IgnoredEquatable
import enum TangemLocalization.Localization

/// Represents the content of a confirmation dialog.
///
/// Use this type to describe the data needed to present a confirmation dialog,
/// including its title, optional subtitle, and the list of action buttons.
///
/// Used with the combination of `View.confirmationDialog(viewModel:)` modifier to show a SwiftUI confirmation dialog.
public struct ConfirmationDialogViewModel: Hashable {
    /// The main title displayed at the top of the dialog.
    public let title: String?

    /// The optional subtitle displayed below the main title.
    public let subtitle: String?

    /// The buttons displayed in the dialog.
    public let buttons: [Button]

    public init(title: String?, subtitle: String? = nil, buttons: [Button]) {
        self.title = title
        self.subtitle = subtitle
        self.buttons = buttons
    }
}

public extension ConfirmationDialogViewModel {
    /// Describes a single action button in a confirmation dialog.
    ///
    /// Each button has a title, an optional semantic role, and an action closure executed when the user selects the button.
    struct Button: Hashable {
        /// The title displayed on the button.
        public let title: String

        /// The optional role that describes the semantic meaning of the button, such as `.cancel` or `.destructive`.
        public let role: ButtonRole?

        /// The closure executed when the button is selected.
        @IgnoredEquatable
        public var action: () -> Void

        public init(title: String, role: ButtonRole? = nil, action: @escaping () -> Void) {
            self.title = title
            self.role = role
            self.action = action
        }

        /// A predefined cancel button that dismisses the dialog without performing any action.
        public static let cancel = Button(title: Localization.commonCancel, role: .cancel, action: {})
    }

    /// A semantic role that describes the purpose of a confirmation dialog button.
    ///
    /// - Note: This type exists to decouple the presentation layer from the SwiftUI framework,
    ///   preventing direct use of `SwiftUI.ButtonRole` in view models or other non-UI code.
    enum ButtonRole: Hashable {
        /// Indicates an action that performs a potentially destructive operation, such as deleting data or removing an item.
        case destructive

        /// Indicates an action that cancels the current operation or dismisses the dialog.
        case cancel
    }
}
