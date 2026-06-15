//
//  EditAddressBookContactManagementInteractor.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemAccounts
import TangemFoundation
import TangemLocalization
import TangemUI

final class EditAddressBookContactManagementInteractor {
    typealias DraftRow = AddressBookContactManagementViewModel.DraftRow
    typealias WalletRowType = AddressBookContactManagementViewModel.WalletRowType
    typealias MainButtonState = AddressBookContactManagementViewModel.MainButtonState

    private let contact: AddressBookContact

    private let nameSubject: CurrentValueSubject<String, Never>
    private let colorSubject: CurrentValueSubject<AccountModel.CompositeIcon.Color, Never>
    private let addressesSubject: CurrentValueSubject<[DraftRow], Never>
    private let walletSubject: CurrentValueSubject<WalletRowType?, Never>

    init(contact: AddressBookContact) {
        self.contact = contact

        nameSubject = .init(contact.name)
        colorSubject = .init(AccountModel.CompositeIcon.Color(rawValue: contact.icon) ?? AccountModelUtils.UI.newAccountIcon().color)
        addressesSubject = .init(contact.addresses.map { DraftRow(id: $0.id.uuidString, address: $0.address) })
        walletSubject = .init(WalletRowType(wallet: contact.walletName, isEditable: true))
    }
}

// MARK: - AddressBookContactManagementInteractor

extension EditAddressBookContactManagementInteractor: AddressBookContactManagementInteractor {
    var title: String { Localization.addressBookContact }

    var contactNamePublisher: AnyPublisher<String, Never> {
        nameSubject.eraseToAnyPublisher()
    }

    var contactColorPublisher: AnyPublisher<AccountModel.CompositeIcon.Color, Never> {
        colorSubject.eraseToAnyPublisher()
    }

    var addressesPublisher: AnyPublisher<[DraftRow], Never> {
        addressesSubject.eraseToAnyPublisher()
    }

    var walletPublisher: AnyPublisher<WalletRowType?, Never> {
        walletSubject.eraseToAnyPublisher()
    }

    var possibleToAddNewAddress: AnyPublisher<Bool, Never> {
        addressesSubject.map { $0.count < 20 }.eraseToAnyPublisher()
    }

    var possibleToDeleteContact: AnyPublisher<Bool, Never> {
        Just(true).eraseToAnyPublisher()
    }

    var mainButtonStatePublisher: AnyPublisher<MainButtonState, Never> {
        Publishers.CombineLatest(nameSubject, addressesSubject)
            .map { name, addresses in
                let isValid = !name.trimmed().isEmpty && !addresses.isEmpty
                return isValid ? .enabled(icon: nil) : .disabled
            }
            .eraseToAnyPublisher()
    }

    func update(name: String) {
        nameSubject.send(name.trimmed())
    }

    func update(color: AccountModel.CompositeIcon.Color) {
        colorSubject.send(color)
    }

    func add(address: DraftRow) throws {
        addressesSubject.value.append(address)
    }

    func deleteAddress(id: String) {
        addressesSubject.value.removeAll { $0.id == id }
    }

    func save() async throws {
        // [REDACTED_TODO_COMMENT]
    }

    func delete() async throws {
        // [REDACTED_TODO_COMMENT]
    }
}
