//
//  AddressBookContactManagementCoordinator.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemFoundation

class AddressBookContactManagementCoordinator: CoordinatorObject {
    @Injected(\.floatingSheetPresenter) private var floatingSheetPresenter: FloatingSheetPresenter

    let dismissAction: Action<Void>
    let popToRootAction: Action<PopToRootOptions>

    // MARK: - Root view model

    @Published private(set) var rootViewModel: AddressBookContactManagementViewModel?

    // MARK: - Child view models

    @Published var addAddressViewModel: AddressBookAddAddressViewModel?
    @Published var chooseNetworkViewModel: ChooseNetworkViewModel?

    // MARK: - Child coordinators

    @Published var qrScanCoordinator: MainQRScanCoordinator?

    required init(
        dismissAction: @escaping Action<Void>,
        popToRootAction: @escaping Action<PopToRootOptions>
    ) {
        self.dismissAction = dismissAction
        self.popToRootAction = popToRootAction
    }

    func start(with options: Options) {
        let interactor: AddressBookContactManagementInteractor
        let focusesNameOnFirstAppear: Bool

        switch options {
        case .add(let addressBookWallet, let prefilledEntries):
            interactor = CreateAddressBookContactManagementInteractor(
                addressBookWallet: addressBookWallet,
                prefilledEntries: prefilledEntries
            )
            focusesNameOnFirstAppear = prefilledEntries.isNotEmpty
        case .edit(let contact, let addressBookWallet):
            interactor = EditAddressBookContactManagementInteractor(contact: contact, initialAddressBookWallet: addressBookWallet)
            focusesNameOnFirstAppear = false
        }

        let addressBooksProvider: any AddressBooksProvider = AllWalletsAddressBooksProvider()
        rootViewModel = AddressBookContactManagementViewModel(
            interactor: interactor,
            coordinator: self,
            addressBooksProvider: addressBooksProvider,
            focusesNameOnFirstAppear: focusesNameOnFirstAppear
        )
    }
}

// MARK: - Options

extension AddressBookContactManagementCoordinator {
    enum Options {
        case add(addressBookWallet: AddressBookWallet, prefilledEntries: [AddressBookEntryDraft])
        case edit(contact: AddressBookContact, addressBookWallet: AddressBookWallet)
    }
}

// MARK: - AddressBookContactManagementRoutable

extension AddressBookContactManagementCoordinator: AddressBookContactManagementRoutable {
    func dismissContactManagement() {
        dismiss(with: ())
    }

    func openAddAddress(userWalletInfo: UserWalletInfo, output: any AddressBookAddAddressOutput, options: AddressBookAddAddressOptions, reservedContacts: [AddressBookContact]) {
        let interactor = CommonAddressBookAddAddressInteractor(userWalletInfo: userWalletInfo, output: output, options: options, reservedContacts: reservedContacts)
        addAddressViewModel = AddressBookAddAddressViewModel(interactor: interactor, coordinator: self, options: options)
    }

    func presentAddressActions(_ viewModel: AddressActionsViewModel) {
        Task { @MainActor in
            floatingSheetPresenter.enqueue(sheet: viewModel)
        }
    }

    func dismissAddressActions() {
        Task { @MainActor in
            floatingSheetPresenter.removeActiveSheet()
        }
    }

    func presentWalletPicker(_ viewModel: AddressBookWalletPickerViewModel) {
        Task { @MainActor in
            floatingSheetPresenter.enqueue(sheet: viewModel)
        }
    }

    func dismissWalletPicker() {
        Task { @MainActor in
            floatingSheetPresenter.removeActiveSheet()
        }
    }
}

// MARK: - AddressBookAddAddressRoutable

extension AddressBookContactManagementCoordinator: AddressBookAddAddressRoutable {
    func dismissAddAddress() {
        addAddressViewModel = nil
    }

    func dismissAddAddressFlow() {
        dismiss(with: ())
    }

    func presentChooseNetwork(_ viewModel: ChooseNetworkViewModel) {
        chooseNetworkViewModel = viewModel
    }

    func dismissChooseNetwork() {
        chooseNetworkViewModel = nil
    }

    func openQRScanner(completion: @escaping (String) -> Void) {
        let dismissAction: Action<String?> = { [weak self] scannedCode in
            self?.qrScanCoordinator = nil

            if let scannedCode {
                completion(scannedCode)
            }
        }

        let coordinator = MainQRScanCoordinator(dismissAction: dismissAction, popToRootAction: popToRootAction)
        coordinator.start(with: .init())
        qrScanCoordinator = coordinator
    }
}
