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
    private let initialSnapshot: AddressBookContactSnapshot

    init(addressBookWallet: AddressBookWallet, addressBooksProvider: any AddressBooksProvider = .common()) {
        self.addressBooksProvider = addressBooksProvider

        nameSubject = .init("")
        colorSubject = .init(CompositeIconColor.randomElement())
        addressesSubject = .init([])
        walletSubject = .init(addressBookWallet)

        initialSnapshot = Self.makeSnapshot(
            name: nameSubject.value,
            color: colorSubject.value,
            wallet: walletSubject.value,
            addresses: addressesSubject.value
        )
    }
}

// MARK: - AddressBookContactManagementInteractor

extension CreateAddressBookContactManagementInteractor: AddressBookContactManagementInteractor {
    var title: String { Localization.addressBookAddContact }

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

    func save() async throws {
        let name = try AddressBookContactNameValidator().validate(nameSubject.value)
        let addressBookManager = walletSubject.value.addressBookManager

        guard let entries = AddressBookContactDraftEntries(addressesSubject.value) else {
            throw AddressBookValidationError.noEntries
        }

        try await addressBookManager.createContact(name: name, appearance: AddressBookContactAppearance(color: colorSubject.value), entries: entries)
    }

    func delete() async throws {}
}
