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
        let interactor: AddressBookContactManagementInteractor = switch options {
        case .add(let addressBookWallet):
            CreateAddressBookContactManagementInteractor(addressBookWallet: addressBookWallet)
        case .edit(let contact, let addressBookWallet):
            EditAddressBookContactManagementInteractor(contact: contact, addressBookWallet: addressBookWallet)
        }

        rootViewModel = AddressBookContactManagementViewModel(interactor: interactor, coordinator: self)
    }
}

// MARK: - Options

extension AddressBookContactManagementCoordinator {
    enum Options {
        case add(addressBookWallet: AddressBookWallet)
        case edit(contact: AddressBookContact, addressBookWallet: AddressBookWallet)
    }
}

// MARK: - AddressBookContactManagementRoutable

extension AddressBookContactManagementCoordinator: AddressBookContactManagementRoutable {
    func dismissContactManagement() {
        dismiss(with: ())
    }

    func openAddAddress(userWalletInfo: UserWalletInfo, output: any AddressBookAddAddressOutput, options: AddressBookAddAddressOptions) {
        let interactor = CommonAddressBookAddAddressInteractor(userWalletInfo: userWalletInfo, output: output, options: options)
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
}

// MARK: - AddressBookAddAddressRoutable

extension AddressBookContactManagementCoordinator: AddressBookAddAddressRoutable {
    func dismissAddAddress() {
        addAddressViewModel = nil
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
