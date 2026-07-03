//
//  AddressBooksCoordinator.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemFoundation

class AddressBooksCoordinator: CoordinatorObject {
    @Injected(\.floatingSheetPresenter) private var floatingSheetPresenter: FloatingSheetPresenter

    let dismissAction: Action<Void>
    let popToRootAction: Action<PopToRootOptions>

    // MARK: - Root view model

    @Published private(set) var rootViewModel: AddressBooksViewModel?

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
        rootViewModel = .init(
            coordinator: self,
            addressBooksProvider: options.addressBooksProvider,
            selectionOutput: options.selectionOutput
        )
    }
}

// MARK: - Options

extension AddressBooksCoordinator {
    struct Options {
        let addressBooksProvider: any AddressBooksProvider
        let selectionOutput: AddressBooksSelectionOutput?

        init(
            addressBooksProvider: any AddressBooksProvider,
            selectionOutput: AddressBooksSelectionOutput? = nil
        ) {
            self.addressBooksProvider = addressBooksProvider
            self.selectionOutput = selectionOutput
        }
    }
}

// MARK: - AddressBooksRoutable

extension AddressBooksCoordinator: AddressBooksRoutable {
    func openAddContact(addressBookWallet: AddressBookWallet) {
        openContactManagement(options: .add(addressBookWallet: addressBookWallet, prefilledEntries: []))
    }

    func openEditContact(contact: AddressBookContact, addressBookWallet: AddressBookWallet) {
        openContactManagement(options: .edit(contact: contact, addressBookWallet: addressBookWallet))
    }

    func openChooseAddress(groups: [AddressBookContactAddressGroup], output: ChooseAddressOutput) {
        let viewModel = ChooseAddressViewModel(groups: groups, router: self, output: output)

        Task { @MainActor in
            floatingSheetPresenter.enqueue(sheet: viewModel)
        }
    }
}

// MARK: - ChooseAddressRoutable

extension AddressBooksCoordinator: ChooseAddressRoutable {
    func dismissChooseAddress() {
        Task { @MainActor in
            floatingSheetPresenter.removeActiveSheet()
        }
    }
}

// MARK: - Private

private extension AddressBooksCoordinator {
    func openContactManagement(options: AddressBookContactManagementCoordinator.Options) {
        let dismissAction: Action<Void> = { [weak self] _ in
            self?.contactManagementCoordinator = nil
        }

        let coordinator = AddressBookContactManagementCoordinator(dismissAction: dismissAction, popToRootAction: popToRootAction)
        coordinator.start(with: options)
        contactManagementCoordinator = coordinator
    }
}
