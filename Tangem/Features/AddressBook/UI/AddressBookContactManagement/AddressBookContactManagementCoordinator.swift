//
//  AddressBookContactManagementCoordinator.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine

class AddressBookContactManagementCoordinator: CoordinatorObject {
    let dismissAction: Action<Void>
    let popToRootAction: Action<PopToRootOptions>

    // MARK: - Root view model

    @Published private(set) var rootViewModel: AddressBookContactManagementViewModel?

    required init(
        dismissAction: @escaping Action<Void>,
        popToRootAction: @escaping Action<PopToRootOptions>
    ) {
        self.dismissAction = dismissAction
        self.popToRootAction = popToRootAction
    }

    func start(with options: Options) {
        let interactor: AddressBookContactManagementInteractor = switch options {
        case .add:
            CreateAddressBookContactManagementInteractor()
        case .edit(let contact):
            EditAddressBookContactManagementInteractor(contact: contact)
        }

        rootViewModel = AddressBookContactManagementViewModel(interactor: interactor, coordinator: self)
    }
}

// MARK: - Options

extension AddressBookContactManagementCoordinator {
    enum Options {
        case add
        case edit(contact: AddressBookContact)
    }
}

// MARK: - AddressBookContactManagementRoutable

extension AddressBookContactManagementCoordinator: AddressBookContactManagementRoutable {
    func dismissContactManagement() {
        dismiss(with: ())
    }
}
