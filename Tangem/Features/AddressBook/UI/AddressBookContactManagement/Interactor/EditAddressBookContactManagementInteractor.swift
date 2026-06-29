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
    private let contact: AddressBookContact
    private let addressBooksProvider: any AddressBooksProvider

    private let nameSubject: CurrentValueSubject<String, Never>
    private let colorSubject: CurrentValueSubject<AccountModel.CompositeIcon.Color, Never>
    private let addressesSubject: CurrentValueSubject<[AddressBookEntryDraft], Never>
    private let walletSubject: CurrentValueSubject<AddressBookWallet, Never>

    init(contact: AddressBookContact, addressBookWallet: AddressBookWallet, addressBooksProvider: any AddressBooksProvider = .common()) {
        self.contact = contact
        self.addressBooksProvider = addressBooksProvider

        nameSubject = .init(contact.name.value)
        colorSubject = .init(AccountModel.CompositeIcon.Color(rawValue: contact.iconColor) ?? AccountModelUtils.UI.newAccountIcon().color)
        addressesSubject = .init(contact.entries.raw.map {
            AddressBookEntryDraft(id: $0.id, address: $0.address, blockchain: $0.blockchain, memo: $0.memo)
        })
        walletSubject = .init(addressBookWallet)
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

    var possibleToDeleteContact: AnyPublisher<Bool, Never> {
        Just(true).eraseToAnyPublisher()
    }

    var isMainButtonEnabledPublisher: AnyPublisher<Bool, Never> {
        Publishers.CombineLatest(nameSubject, addressesSubject)
            .map { name, addresses in
                !name.trimmed().isEmpty && !addresses.isEmpty
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
        let source = try sourceAddressBookWallet()
        let target = walletSubject.value

        // Deleting the last address deletes the contact; the chosen wallet is moot when nothing remains.
        guard let entries = AddressBookContactDraftEntries(addressesSubject.value) else {
            try await source.addressBookManager.deleteContact(id: contact.id)
            return
        }

        if target.wallet.id == contact.walletId {
            try await target.addressBookManager.updateContact(id: contact.id, name: name, iconColor: colorSubject.value.rawValue, entries: entries)
        } else {
            try await move(from: source, to: target, name: name, iconColor: colorSubject.value.rawValue, entries: entries)
        }
    }

    func delete() async throws {
        try await sourceAddressBookWallet().addressBookManager.deleteContact(id: contact.id)
    }
}

// MARK: - Wallet change (move between books)

private extension EditAddressBookContactManagementInteractor {
    /// The book the contact currently lives in — resolved from its own `walletId` rather than stored, so it
    /// stays the source even after `walletSubject` is switched to the wallet the user wants to move it to.
    func sourceAddressBookWallet() throws -> AddressBookWallet {
        guard let wallet = addressBooksProvider.addressBooks.first(where: { $0.wallet.id == contact.walletId }) else {
            throw AddressBookManagerError.contactNotFound
        }

        return wallet
    }

    /// Each book is signed with its owning wallet's key, so the move re-signs the contact's entries under the
    /// target wallet — keeping its `id` — then drops it from the source book. Re-sign first so a cancelled
    /// signing ceremony leaves the original untouched: the contact is never absent from both books, and the
    /// re-signed copy is rolled back if the source delete fails.
    func move(
        from source: AddressBookWallet,
        to target: AddressBookWallet,
        name: AddressBookContactName,
        iconColor: String,
        entries: AddressBookContactDraftEntries
    ) async throws {
        try await target.addressBookManager.reSignContact(id: contact.id, name: name, iconColor: iconColor, entries: entries)

        do {
            try await source.addressBookManager.deleteContact(id: contact.id)
        } catch {
            do {
                try await target.addressBookManager.deleteContact(id: contact.id)
            } catch let rollbackError {
                AppLogger.error("Address book: move rollback failed, contact may now exist in both wallets", error: rollbackError)
            }
            throw error
        }
    }
}
