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
        case .add: CreateAddressBookContactManagementInteractor()
        case .edit(let contact): EditAddressBookContactManagementInteractor(contact: contact)
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

    func openAddAddress(userWalletInfo: UserWalletInfo, output: any AddressBookAddAddressOutput) {
        let interactor = CommonAddressBookAddAddressInteractor(userWalletInfo: userWalletInfo, output: output)
        addAddressViewModel = AddressBookAddAddressViewModel(interactor: interactor, coordinator: self)
    }
}

// MARK: - AddressBookAddAddressRoutable

extension AddressBookContactManagementCoordinator: AddressBookAddAddressRoutable {
    func dismissAddAddress() {
        addAddressViewModel = nil
    }

    func openQRScanner() {
        let dismissAction: Action<String?> = { [weak self] scannedCode in
            self?.qrScanCoordinator = nil

            if let scannedCode {
                self?.addAddressViewModel?.applyScannedAddress(scannedCode)
            }
        }

        let coordinator = MainQRScanCoordinator(dismissAction: dismissAction, popToRootAction: popToRootAction)
        coordinator.start(with: .init())
        qrScanCoordinator = coordinator
    }
}
