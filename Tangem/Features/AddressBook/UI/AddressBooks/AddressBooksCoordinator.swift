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

    private let analyticsLogger: any AddressBookAnalyticsLogger = CommonAddressBookAnalyticsLogger()

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
            selectionOutput: options.selectionOutput,
            analyticsLogger: analyticsLogger
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
        openAddContact(addressBookWallet: addressBookWallet, prefilledEntries: [])
    }

    func openChooseAddress(contact: AddressBookContact, output: ChooseAddressOutput) {
        let viewModel = ChooseAddressViewModel(groups: contact.entries.groupedByAddress, router: self) { [weak output] group in
            output?.chooseAddressDidSelect(group, of: contact)
        }

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

// MARK: - AddressBookContactNavigating

extension AddressBooksCoordinator: AddressBookContactNavigating {}
