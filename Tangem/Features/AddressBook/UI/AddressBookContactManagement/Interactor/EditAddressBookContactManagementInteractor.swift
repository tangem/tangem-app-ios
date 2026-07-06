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

    /// The book the contact was opened from. Stored (not re-resolved) so it stays the source even after
    /// `walletSubject` is switched to the wallet the user wants to move the contact to.
    private let initialAddressBookWallet: AddressBookWallet

    private let nameSubject: CurrentValueSubject<String, Never>
    private let colorSubject: CurrentValueSubject<AccountModel.CompositeIcon.Color, Never>
    private let addressesSubject: CurrentValueSubject<[AddressBookEntryDraft], Never>
    private let walletSubject: CurrentValueSubject<AddressBookWallet, Never>

    private let initialSnapshot: AddressBookContactSnapshot
    private let analyticsLogger: any AddressBookAnalyticsLogger

    init(
        contact: AddressBookContact,
        initialAddressBookWallet: AddressBookWallet,
        analyticsLogger: any AddressBookAnalyticsLogger
    ) {
        self.contact = contact
        self.initialAddressBookWallet = initialAddressBookWallet
        self.analyticsLogger = analyticsLogger

        nameSubject = .init(contact.name.value)
        colorSubject = .init(contact.appearance.color)
        addressesSubject = .init(contact.entries.raw.map {
            AddressBookEntryDraft(id: $0.id, address: $0.address, blockchain: $0.blockchain, memo: $0.memo)
        })
        walletSubject = .init(initialAddressBookWallet)

        initialSnapshot = Self.makeSnapshot(
            name: nameSubject.value,
            color: colorSubject.value,
            wallet: walletSubject.value,
            addresses: addressesSubject.value
        )
    }
}

// MARK: - AddressBookContactManagementInteractor

extension EditAddressBookContactManagementInteractor: AddressBookContactManagementInteractor {
    var title: String { Localization.addressBookContact }
    var mainButtonTitle: String { Localization.addressBookSaveContact }
    var saveErrorMessage: String? { nil }

    var contactId: AddressBookContactID? { contact.id }

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

    var reservedContacts: [AddressBookContact] {
        walletSubject.value.addressBookManager.contacts.filter { $0.id != contact.id }
    }

    var isNameTakenPublisher: AnyPublisher<Bool, Never> {
        nameTakenPublisher
    }

    var isMainButtonEnabledPublisher: AnyPublisher<Bool, Never> {
        Publishers.CombineLatest3(nameSubject, addressesSubject, nameTakenPublisher)
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

    var hasUnsavedChanges: Bool {
        Self.makeSnapshot(
            name: nameSubject.value,
            color: colorSubject.value,
            wallet: walletSubject.value,
            addresses: addressesSubject.value
        ) != initialSnapshot
    }

    private static func makeSnapshot(
        name: String,
        color: AccountModel.CompositeIcon.Color,
        wallet: AddressBookWallet,
        addresses: [AddressBookEntryDraft]
    ) -> AddressBookContactSnapshot {
        AddressBookContactSnapshot(
            name: name.trimmed(),
            color: color,
            walletId: wallet.wallet.id.stringValue,
            entries: Set(addresses.map {
                AddressBookContactSnapshot.Entry(address: $0.address, networkId: $0.networkId.rawValue, memo: $0.memo ?? "")
            })
        )
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

    func save() async throws -> AddressBookContactID {
        do {
            let name = try AddressBookContactNameValidator().validate(nameSubject.value)
            let source = initialAddressBookWallet
            let target = walletSubject.value

            // Deleting the last address deletes the contact; the chosen wallet is moot when nothing remains.
            if let entries = AddressBookContactDraftEntries(addressesSubject.value) {
                if target.wallet.id == contact.walletId {
                    try await target.addressBookManager.updateContact(id: contact.id, name: name, appearance: AddressBookContactAppearance(color: colorSubject.value), entries: entries)
                } else {
                    try await move(from: source, to: target, name: name, appearance: AddressBookContactAppearance(color: colorSubject.value), entries: entries)
                }
            } else {
                try await source.addressBookManager.deleteContact(id: contact.id)
            }

            analyticsLogger.logContactSaved(walletId: analyticsWalletId, contactId: contact.id.stringValue, mode: .edit)
            return contact.id
        } catch {
            analyticsLogger.logSaveFailure(walletId: analyticsWalletId, contactId: contact.id.stringValue, error: error)
            throw error
        }
    }

    func delete() async throws {
        try await initialAddressBookWallet.addressBookManager.deleteContact(id: contact.id)
        analyticsLogger.logContactDeleted(walletId: contact.walletId.stringValue, contactId: contact.id.stringValue)
    }

    func logContactScreenOpened() {
        analyticsLogger.logContactScreenOpened(walletId: analyticsWalletId, contactId: contact.id.stringValue)
    }

    func logWalletPickerOpened() {
        analyticsLogger.logButtonSaveTo(walletId: analyticsWalletId)
    }

    func logAddressRemoved() {
        analyticsLogger.logAddressRemoved(walletId: analyticsWalletId, contactId: contact.id.stringValue)
    }
}

// MARK: - Wallet change (move between books)

private extension EditAddressBookContactManagementInteractor {
    var analyticsWalletId: String {
        walletSubject.value.wallet.id.stringValue
    }

    var nameTakenPublisher: AnyPublisher<Bool, Never> {
        walletSubject
            .map { $0.addressBookManager.contactsPublisher }
            .switchToLatest()
            .combineLatest(nameSubject)
            .map { [contactId = contact.id] contacts, name in
                let trimmed = name.trimmed()
                guard !trimmed.isEmpty else { return false }
                return contacts.contains { $0.id != contactId && $0.name.value.caseInsensitiveCompare(trimmed) == .orderedSame }
            }
            .removeDuplicates()
            .eraseToAnyPublisher()
    }

    /// Each book is signed with its owning wallet's key, so the move re-signs the contact's entries under the
    /// target wallet — keeping its `id` — then drops it from the source book. Re-sign first so a cancelled
    /// signing ceremony leaves the original untouched: the contact is never absent from both books, and the
    /// re-signed copy is rolled back if the source delete fails.
    func move(
        from source: AddressBookWallet,
        to target: AddressBookWallet,
        name: AddressBookContactName,
        appearance: AddressBookContactAppearance,
        entries: AddressBookContactDraftEntries
    ) async throws {
        try await target.addressBookManager.reSignContact(id: contact.id, name: name, appearance: appearance, entries: entries)

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
