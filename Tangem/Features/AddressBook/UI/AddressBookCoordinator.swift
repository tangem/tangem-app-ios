//
//  AddressBookCoordinator.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemFoundation

class AddressBookCoordinator: CoordinatorObject {
    let dismissAction: Action<Void>
    let popToRootAction: Action<PopToRootOptions>

    // MARK: - Root view model

    @Published private(set) var rootViewModel: AddressBookContactsListViewModel?

    // MARK: - Child coordinators

    @Published var contactManagementCoordinator: AddressBookContactManagementCoordinator?

    required init(
        dismissAction: @escaping Action<Void>,
        popToRootAction: @escaping Action<PopToRootOptions>
    ) {
        self.dismissAction = dismissAction
        self.popToRootAction = popToRootAction
    }

    func start(with options: Options) {
        rootViewModel = .init(coordinator: self)
    }
}

// MARK: - Options

extension AddressBookCoordinator {
    enum Options {
        case `default`
    }
}

// MARK: - AddressBookContactsListRoutable

extension AddressBookCoordinator: AddressBookContactsListRoutable {
    func openAddContact(walletId: UserWalletId, addressBookManager: AddressBookManager) {
        openContactManagement(options: .add(walletId: walletId, addressBookManager: addressBookManager))
    }

    func openEditContact(contact: AddressBookContact, walletId: UserWalletId, addressBookManager: AddressBookManager) {
        openContactManagement(options: .edit(contact: contact, walletId: walletId, addressBookManager: addressBookManager))
    }
}

// MARK: - Private

private extension AddressBookCoordinator {
    func openContactManagement(options: AddressBookContactManagementCoordinator.Options) {
        let dismissAction: Action<Void> = { [weak self] _ in
            self?.contactManagementCoordinator = nil
        }

        let coordinator = AddressBookContactManagementCoordinator(dismissAction: dismissAction, popToRootAction: popToRootAction)
        coordinator.start(with: options)
        contactManagementCoordinator = coordinator
    }
}
