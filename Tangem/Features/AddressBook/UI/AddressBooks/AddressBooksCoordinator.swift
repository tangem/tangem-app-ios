//
//  AddressBooksCoordinator.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine

class AddressBooksCoordinator: CoordinatorObject {
    let dismissAction: Action<Void>
    let popToRootAction: Action<PopToRootOptions>

    // MARK: - Root view model

    @Published private(set) var rootViewModel: AddressBooksViewModel?

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

extension AddressBooksCoordinator {
    enum Options {
        case `default`
    }
}

// MARK: - AddressBooksRoutable

extension AddressBooksCoordinator: AddressBooksRoutable {
    func openAddContact() {
        // [REDACTED_TODO_COMMENT]
    }

    func openEditContact(contact: AddressBookContact) {
        // [REDACTED_TODO_COMMENT]
    }
}
