//
//  CreateAddressBookContactManagementInteractor.swift
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

final class CreateAddressBookContactManagementInteractor {
    private let nameSubject: CurrentValueSubject<String, Never>
    private let colorSubject: CurrentValueSubject<AccountModel.CompositeIcon.Color, Never>
    private let addressesSubject: CurrentValueSubject<[AddressBookEntryDraft], Never>
    private let walletSubject: CurrentValueSubject<AddressBookWallet, Never>
    private let addressBooksProvider: any AddressBooksProvider

    init(addressBookWallet: AddressBookWallet, addressBooksProvider: any AddressBooksProvider = .common()) {
        self.addressBooksProvider = addressBooksProvider

        nameSubject = .init("")
        colorSubject = .init(AccountModelUtils.UI.newAccountIcon().color)
        addressesSubject = .init([])
        walletSubject = .init(addressBookWallet)
    }
}

// MARK: - AddressBookContactManagementInteractor

extension CreateAddressBookContactManagementInteractor: AddressBookContactManagementInteractor {
    var title: String { Localization.addressBookNewContact }
    var mainButtonTitle: String { Localization.addressBookAddContact }
    var saveErrorMessage: String? { Localization.addressBookCreatingError }

    var contactNamePublisher: AnyPublisher<String, Never> {
        nameSubject.eraseToAnyPublisher()
    }

    var contactColorPublisher: AnyPublisher<AccountModel.CompositeIcon.Color, Never> {
        colorSubject.eraseToAnyPublisher()
    }

    var addressesPublisher: AnyPublisher<AddressBookContactDraftEntries?, Never> {
        addressesSubject.map { AddressBookContactDraftEntries($0) }.removeDuplicates().eraseToAnyPublisher()
    }

    var walletPublisher: AnyPublisher<AddressBookWallet, Never> {
        walletSubject.eraseToAnyPublisher()
    }

    var possibleToAddNewAddress: AnyPublisher<Bool, Never> {
        addressesSubject
            .map { $0.uniqueProperties(\.address).count < AddressBookContactDraftEntries.maxAddressCount }
            .removeDuplicates()
            .eraseToAnyPublisher()
    }

    var possibleToDeleteContact: AnyPublisher<Bool, Never> { Just(false).eraseToAnyPublisher() }

    var reservedAddresses: [AddressBookReservedAddress] {
        walletSubject.value.addressBookManager.contacts.flatMap { other in
            other.entries.raw.map { AddressBookReservedAddress(address: $0.address, networkId: $0.networkId, contactName: other.name.value) }
        }
    }

    var isNameTakenPublisher: AnyPublisher<Bool, Never> {
        nameTakenPublisher()
    }

    var isMainButtonEnabledPublisher: AnyPublisher<Bool, Never> {
        Publishers.CombineLatest3(nameSubject, addressesSubject, nameTakenPublisher())
            .map { name, addresses, isNameTaken in
                !name.trimmed().isEmpty && !addresses.isEmpty && !isNameTaken
            }
            .eraseToAnyPublisher()
    }

    var mainButtonIconPublisher: AnyPublisher<MainButton.Icon?, Never> {
        walletSubject
            .map { addressBookWallet in
                CommonTangemIconProvider(config: addressBookWallet.wallet.config).getMainButtonIcon()
            }
            .eraseToAnyPublisher()
    }

    func update(name: String) {
        nameSubject.send(name)
    }

    func update(color: AccountModel.CompositeIcon.Color) {
        colorSubject.send(color)
    }

    func update(addressBookWallet: AddressBookWallet) {
        walletSubject.send(addressBookWallet)
    }

    func update(entries: [AddressBookEntryDraft], replacing ids: [AddressBookAddressEntryID]) throws {
        let remaining = addressesSubject.value.filter { !ids.contains($0.id) }
        try AddressBookContactDraftEntries.validate(adding: entries, to: remaining)

        addressesSubject.value = remaining + entries
    }

    func deleteAddress(id: AddressBookAddressEntryID) {
        addressesSubject.value.removeAll { $0.id == id }
    }

    func save() async throws {
        let name = try AddressBookContactNameValidator().validate(nameSubject.value)
        let addressBookManager = walletSubject.value.addressBookManager

        guard let entries = AddressBookContactDraftEntries(addressesSubject.value) else {
            throw AddressBookValidationError.noEntries
        }

        try await addressBookManager.createContact(name: name, iconColor: colorSubject.value.rawValue, entries: entries)
    }

    func delete() async throws {}
}

// MARK: - Private

private extension CreateAddressBookContactManagementInteractor {
    func nameTakenPublisher() -> AnyPublisher<Bool, Never> {
        walletSubject
            .map { $0.addressBookManager.contactsPublisher }
            .switchToLatest()
            .combineLatest(nameSubject)
            .map { contacts, name in
                let trimmed = name.trimmed()
                guard !trimmed.isEmpty else { return false }
                return contacts.contains { $0.name.value.caseInsensitiveCompare(trimmed) == .orderedSame }
            }
            .removeDuplicates()
            .eraseToAnyPublisher()
    }
}
