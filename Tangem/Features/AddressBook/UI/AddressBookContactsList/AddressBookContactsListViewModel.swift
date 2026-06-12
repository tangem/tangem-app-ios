//
//  AddressBookContactsListViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemUI

final class AddressBookContactsListViewModel: ObservableObject {
    // MARK: - ViewState

    @Published var selectedChipId: String?
    @Published private(set) var walletChips: [Chip] = []
    @Published private(set) var contactsViewModels: [AddressBookContactViewModel] = []

    // MARK: - Dependencies

    @Injected(\.userWalletRepository)
    private var userWalletRepository: UserWalletRepository

    private weak var coordinator: AddressBookContactsListRoutable?
    private let addressBooksProvider: any AddressBooksProvider
    private let addressBooks: [AddressBookWallet]

    init(
        coordinator: AddressBookContactsListRoutable,
        addressBooksProvider: any AddressBooksProvider = .common()
    ) {
        self.coordinator = coordinator
        self.addressBooksProvider = addressBooksProvider
        addressBooks = addressBooksProvider.addressBooks

        setupChips()
        bind()
    }

    func openAddContact() {
        guard let addressBook = selectedAddressBook else { return }

        coordinator?.openAddContact(addressBookManager: addressBook.addressBookManager)
    }
}

// MARK: - Private

private extension AddressBookContactsListViewModel {
    var selectedAddressBook: AddressBookWallet? {
        addressBooks.first { $0.wallet.id.stringValue == selectedChipId }
    }

    func setupChips() {
        guard addressBooks.count >= 2 else {
            walletChips = []
            selectedChipId = addressBooks.first?.wallet.id.stringValue
            return
        }

        walletChips = addressBooks.map { Chip(id: $0.wallet.id.stringValue, title: $0.wallet.name) }

        let chipIds = walletChips.map(\.id)
        if let currentWalletId = userWalletRepository.selectedModel?.userWalletId.stringValue,
           chipIds.contains(currentWalletId) {
            selectedChipId = currentWalletId
        } else {
            selectedChipId = walletChips.first?.id
        }
    }

    func bind() {
        $selectedChipId
            .withWeakCaptureOf(self)
            .compactMap { viewModel, selectedChipId -> AddressBookWallet? in
                viewModel.addressBooks
                    .first(where: { $0.wallet.id.stringValue == selectedChipId })
            }
            .withWeakCaptureOf(self)
            .flatMapLatest { viewModel, addressBook in
                addressBook.addressBookPublisher
                    .withWeakCaptureOf(viewModel)
                    .map { $0.mapToAddressBookContactViewModels(addressBook: addressBook, contacts: $1.contacts) }
            }
            .receive(on: DispatchQueue.main)
            .assign(to: &$contactsViewModels)
    }

    func mapToAddressBookContactViewModels(addressBook: AddressBookWallet, contacts: [AddressBookContact]) -> [AddressBookContactViewModel] {
        contacts.map { contact in
            AddressBookContactViewModel(contact: contact) { [weak self] in
                self?.coordinator?.openEditContact(addressBookManager: addressBook.addressBookManager, contact: contact)
            }
        }
    }
}
