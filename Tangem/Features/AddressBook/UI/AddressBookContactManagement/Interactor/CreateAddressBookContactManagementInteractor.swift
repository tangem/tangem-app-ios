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
    typealias WalletRowType = AddressBookContactManagementViewModel.WalletRowType

    @Injected(\.userWalletRepository)
    private static var userWalletRepository: UserWalletRepository

    private let nameSubject: CurrentValueSubject<String, Never>
    private let colorSubject: CurrentValueSubject<AccountModel.CompositeIcon.Color, Never>
    private let addressesSubject: CurrentValueSubject<[AddressBookEntryDraft], Never>
    private let walletSubject: CurrentValueSubject<UserWalletInfo?, Never>

    private let walletId: UserWalletId

    private var addressBookManager: AddressBookManager? {
        Self.userWalletRepository.models.first { $0.userWalletId == walletId }?.addressBookManager
    }

    init(walletId: UserWalletId) {
        self.walletId = walletId

        nameSubject = .init("")
        colorSubject = .init(AccountModelUtils.UI.newAccountIcon().color)
        addressesSubject = .init([])
        walletSubject = .init(Self.userWalletRepository.models.first { $0.userWalletId == walletId }?.userWalletInfo)
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

        let name = try AddressBookContactNameValidator().validate(nameSubject.value)

        try await addressBookManager.createContact(name: name, entries: addressesSubject.value)
    }

    func delete() async throws {}
}
