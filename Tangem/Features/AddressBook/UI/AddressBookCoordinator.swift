//
//  AddressBookCoordinator.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine

class AddressBookCoordinator: CoordinatorObject {
    let dismissAction: Action<Void>
    let popToRootAction: Action<PopToRootOptions>

    // MARK: - Root view model

    @Published private(set) var rootViewModel: AddressBookContactsListViewModel?

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
    func openAddContact() {
        // [REDACTED_TODO_COMMENT]
    }

    func openEditContact(contact: AddressBookContact) {
        // [REDACTED_TODO_COMMENT]
    }
}
