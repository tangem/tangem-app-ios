//
//  AddressBookContactNavigating.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

/// A helper that helps to perform the common navigation flow: present the `Address Book Contact` editor.
/// Same idea as in the `FeeCurrencyNavigating`.
protocol AddressBookContactNavigating where Self: AnyObject, Self: CoordinatorObject {
    var contactManagementCoordinator: AddressBookContactManagementCoordinator? { get set }

    func contactManagementDidDismiss()
}

// MARK: - Default implementation

extension AddressBookContactNavigating {
    func contactManagementDidDismiss() {}

    func openAddContact(addressBookWallet: AddressBookWallet, prefilledEntries: [AddressBookEntryDraft]) {
        openContactManagement(with: .add(addressBookWallet: addressBookWallet, prefilledEntries: prefilledEntries))
    }

    func openEditContact(contact: AddressBookContact, addressBookWallet: AddressBookWallet) {
        openContactManagement(with: .edit(contact: contact, addressBookWallet: addressBookWallet))
    }

    func openContactManagement(with options: AddressBookContactManagementCoordinator.Options) {
        let dismissAction: Action<Void> = { [weak self] _ in
            self?.contactManagementCoordinator = nil
            self?.contactManagementDidDismiss()
        }

        let coordinator = AddressBookContactManagementCoordinator(
            dismissAction: dismissAction,
            popToRootAction: popToRootAction
        )
        coordinator.start(with: options)
        contactManagementCoordinator = coordinator
    }
}
