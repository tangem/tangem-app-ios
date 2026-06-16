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

    private let nameSubject: CurrentValueSubject<String, Never>
    private let colorSubject: CurrentValueSubject<AccountModel.CompositeIcon.Color, Never>
    private let addressesSubject: CurrentValueSubject<[AddressBookEntryDraft], Never>
    private let walletSubject: CurrentValueSubject<UserWalletInfo?, Never>

    private var addressBookManager: AddressBookManager? {
        Self.userWalletRepository.models.first { $0.userWalletId == walletId }?.addressBookManager
    }

    init(contact: AddressBookContact, walletId: UserWalletId) {
        self.contact = contact
        self.walletId = walletId

        nameSubject = .init(contact.name.value)
        colorSubject = .init(AccountModelUtils.UI.newAccountIcon().color)
        addressesSubject = .init(contact.entries.map {
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

    var addressesPublisher: AnyPublisher<[AddressBookEntryDraft], Never> {
        addressesSubject.eraseToAnyPublisher()
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
        addressesSubject.map { $0.count < 20 }.eraseToAnyPublisher()
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
        addressesSubject.value.append(contentsOf: entries)
    }

    func deleteAddress(id: AddressBookAddressEntryID) {
        addressesSubject.value.removeAll { $0.id == id }
    }

    func save() async throws {
        guard let addressBookManager else {
            throw AddressBookManagementError.walletUnavailable
        }

        let contactId = contact.id
        let name = try AddressBookContactNameValidator().validate(nameSubject.value)
        let drafts = addressesSubject.value

        guard !drafts.isEmpty else {
            try await addressBookManager.deleteContact(id: contactId)
            return
        }

        let originalIds = Set(contact.entries.map(\.id))
        let currentIds = Set(drafts.map(\.id))

        // Remove entries the user deleted.
        for entry in contact.entries where !currentIds.contains(entry.id) {
            try await addressBookManager.deleteEntry(id: entry.id, fromContactWith: contactId)
        }

        // `name` is part of the signed tuple, so a rename re-signs every remaining entry.
        if name != contact.name {
            try await addressBookManager.renameContact(id: contactId, to: name)
        }

        // Add freshly entered addresses (drafts whose id is not among the original entries).
        let addedEntries = drafts.filter { !originalIds.contains($0.id) }

        if !addedEntries.isEmpty {
            try await addressBookManager.addEntries(addedEntries, toContactWith: contactId)
        }
    }

    func delete() async throws {
        guard let addressBookManager else {
            throw AddressBookManagementError.walletUnavailable
        }

        try await addressBookManager.deleteContact(id: contact.id)
    }
}
