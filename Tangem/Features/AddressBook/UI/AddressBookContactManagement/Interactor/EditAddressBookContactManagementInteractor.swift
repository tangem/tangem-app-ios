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
    typealias WalletRowType = AddressBookContactManagementViewModel.WalletRowType

    @Injected(\.userWalletRepository)
    private var userWalletRepository: UserWalletRepository

    private let contact: AddressBookContact

    private let nameSubject: CurrentValueSubject<String, Never>
    private let colorSubject: CurrentValueSubject<AccountModel.CompositeIcon.Color, Never>
    private let addressesSubject: CurrentValueSubject<[AddressBookEntryDraft], Never>
    private let walletSubject: CurrentValueSubject<AddressBookWallet, Never>

    init(contact: AddressBookContact, addressBookWallet: AddressBookWallet) {
        self.contact = contact

        nameSubject = .init(contact.name.value)
        colorSubject = .init(AccountModel.CompositeIcon.Color(rawValue: contact.iconColor) ?? AccountModelUtils.UI.newAccountIcon().color)
        addressesSubject = .init(contact.entries.raw.map {
            AddressBookEntryDraft(id: $0.id, address: $0.address, networkId: $0.networkId, memo: $0.memo)
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

    var walletPublisher: AnyPublisher<WalletRowType?, Never> {
        walletSubject
            .map { addressBookWallet -> WalletRowType? in
                WalletRowType(
                    userWalletInfo: addressBookWallet.wallet,
                    isEditable: self.userWalletRepository.models.count > 1
                )
            }
            .eraseToAnyPublisher()
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
        // [REDACTED_TODO_COMMENT]
        walletSubject.send(addressBookWallet)
    }

    func add(entries: [AddressBookEntryDraft]) throws {
        try AddressBookContactDraftEntries.validate(adding: entries, to: addressesSubject.value)

        addressesSubject.value.append(contentsOf: entries)
    }

    func deleteAddress(id: AddressBookAddressEntryID) {
        addressesSubject.value.removeAll { $0.id == id }
    }

    func save() async throws {
        let name = try AddressBookContactNameValidator().validate(nameSubject.value)
        let addressBookManager = walletSubject.value.addressBookManager

        // Deleting the last address deletes the contact; otherwise the whole edit is applied atomically.
        guard let entries = AddressBookContactDraftEntries(addressesSubject.value) else {
            try await addressBookManager.deleteContact(id: contact.id)
            return
        }

        try await addressBookManager.updateContact(id: contact.id, name: name, iconColor: colorSubject.value.rawValue, entries: entries)
    }

    func delete() async throws {
        let addressBookManager = walletSubject.value.addressBookManager
        try await addressBookManager.deleteContact(id: contact.id)
    }
}
