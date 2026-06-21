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
    private static var userWalletRepository: UserWalletRepository

    private let contact: AddressBookContact
    private let walletId: UserWalletId
    private let addressBookManager: AddressBookManager

    private let nameSubject: CurrentValueSubject<String, Never>
    private let colorSubject: CurrentValueSubject<AccountModel.CompositeIcon.Color, Never>
    private let addressesSubject: CurrentValueSubject<[AddressBookEntryDraft], Never>
    private let walletSubject: CurrentValueSubject<UserWalletInfo?, Never>

    init(contact: AddressBookContact, walletId: UserWalletId, addressBookManager: AddressBookManager) {
        self.contact = contact
        self.walletId = walletId
        self.addressBookManager = addressBookManager

        nameSubject = .init(contact.name.value)
        colorSubject = .init(AccountModel.CompositeIcon.Color(rawValue: contact.iconColor) ?? AccountModelUtils.UI.newAccountIcon().color)
        addressesSubject = .init(contact.entries.raw.map {
            AddressBookEntryDraft(id: $0.id, address: $0.address, networkId: $0.networkId, memo: $0.memo)
        })
        walletSubject = .init(Self.userWalletRepository.models.first { $0.userWalletId == walletId }?.userWalletInfo)
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
            .map { walletInfo in
                walletInfo.map {
                    WalletRowType(
                        userWalletInfo: $0,
                        isEditable: Self.userWalletRepository.models.count > 1
                    )
                }
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
            .map { walletInfo in
                walletInfo.flatMap { CommonTangemIconProvider(config: $0.config).getMainButtonIcon() }
            }
            .eraseToAnyPublisher()
    }

    func update(name: String) {
        nameSubject.send(name)
    }

    func update(color: AccountModel.CompositeIcon.Color) {
        colorSubject.send(color)
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

        // Deleting the last address deletes the contact; otherwise the whole edit is applied atomically.
        guard let entries = AddressBookContactDraftEntries(addressesSubject.value) else {
            try await addressBookManager.deleteContact(id: contact.id)
            return
        }

        try await addressBookManager.updateContact(id: contact.id, name: name, iconColor: colorSubject.value.rawValue, entries: entries)
    }

    func delete() async throws {
        try await addressBookManager.deleteContact(id: contact.id)
    }
}
