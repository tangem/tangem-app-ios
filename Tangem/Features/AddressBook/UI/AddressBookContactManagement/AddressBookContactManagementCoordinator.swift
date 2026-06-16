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
    let dismissAction: Action<Void>
    let popToRootAction: Action<PopToRootOptions>

    // MARK: - Root view model

    @Published private(set) var rootViewModel: AddressBookContactManagementViewModel?

    // MARK: - Child view models

    @Published var addAddressViewModel: AddressBookAddAddressViewModel?

    // MARK: - Child coordinators

    @Published var qrScanViewCoordinator: QRScanViewCoordinator?

    required init(
        dismissAction: @escaping Action<Void>,
        popToRootAction: @escaping Action<PopToRootOptions>
    ) {
        self.dismissAction = dismissAction
        self.popToRootAction = popToRootAction
    }

    func start(with options: Options) {
        let interactor: AddressBookContactManagementInteractor = switch options {
        case .add(let walletId): CreateAddressBookContactManagementInteractor(walletId: walletId)
        case .edit(let contact, let walletId): EditAddressBookContactManagementInteractor(contact: contact, walletId: walletId)
        }

        rootViewModel = AddressBookContactManagementViewModel(interactor: interactor, coordinator: self)
    }
}

// MARK: - Options

extension AddressBookContactManagementCoordinator {
    enum Options {
        case add(walletId: UserWalletId)
        case edit(contact: AddressBookContact, walletId: UserWalletId)
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

    func openQRScanner(output: QRScannerOutput) {
        let coordinator = QRScanViewCoordinator { [weak self] in
            self?.qrScanViewCoordinator = nil
        }

        coordinator.start(with: .init(output: output, text: ""))
        qrScanViewCoordinator = coordinator
    }
}
