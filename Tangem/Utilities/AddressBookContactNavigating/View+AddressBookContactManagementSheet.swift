//
//  View+AddressBookContactManagementSheet.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI

extension View {
    /// View-side counterpart of `AddressBookContactNavigating`.
    func addressBookContactManagementSheet(_ coordinator: Binding<AddressBookContactManagementCoordinator?>) -> some View {
        sheet(item: coordinator) { contactManagementCoordinator in
            AddressBookContactManagementCoordinatorView(coordinator: contactManagementCoordinator)
                .presentation(onDismissalAttempt: { contactManagementCoordinator.rootViewModel?.userDidRequestDismiss() })
        }
    }
}
