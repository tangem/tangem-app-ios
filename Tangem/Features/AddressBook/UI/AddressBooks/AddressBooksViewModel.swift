//
//  AddressBooksViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemUI
import TangemFoundation

final class AddressBooksViewModel: ObservableObject {
    // MARK: - ViewState

    @Published var selectedChipId: String?
    @Published private(set) var walletChips: [Chip] = []
    @Published private(set) var contactsViewModels: LoadingResult<[AddressBookContactViewModel], Error> = .loading

    var showsToolbarAddButton: Bool {
        if case .success(let contacts) = contactsViewModels {
            return !contacts.isEmpty
        }
        return false
    }

    // MARK: - Dependencies

    @Injected(\.userWalletRepository)
    private var userWalletRepository: UserWalletRepository

    private weak var coordinator: AddressBooksRoutable?
    private let addressBooksProvider: any AddressBooksProvider
    private let addressBooks: [AddressBookWallet]

    init(
        coordinator: AddressBooksRoutable,
        addressBooksProvider: any AddressBooksProvider = .common()
    ) {
        self.coordinator = coordinator
        self.addressBooksProvider = addressBooksProvider
        addressBooks = addressBooksProvider.addressBooks

        setupChips()
        bind()
    }

    func openAddContact() {
        guard let selectedAddressBook else {
            return
        }

        coordinator?.openAddContact(addressBookWallet: selectedAddressBook)
    }

    func retry() {
        guard let selectedAddressBook else {
            return
        }

        Task { await selectedAddressBook.addressBookManager.load() }
    }
}

// MARK: - Private

private extension AddressBooksViewModel {
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
            .map { viewModel, selectedChipId -> AddressBookWallet? in
                viewModel.addressBooks
                    .first(where: { $0.wallet.id.stringValue == selectedChipId })
            }
            .withWeakCaptureOf(self)
            .flatMapLatest { viewModel, addressBook -> AnyPublisher<LoadingResult<[AddressBookContactViewModel], Error>, Never> in
                guard let addressBook else {
                    return Just(.success([])).eraseToAnyPublisher()
                }

                return Publishers.CombineLatest(addressBook.addressBookPublisher, addressBook.syncStatePublisher)
                    .withWeakCaptureOf(viewModel)
                    .map { viewModel, output -> LoadingResult<[AddressBookContactViewModel], Error> in
                        let (contacts, syncState) = output

                        switch syncState {
                        case .failed:
                            return .failure(AddressBooksLoadError.syncFailed)
                        case .syncing:
                            return .loading
                        case .synced, .offline:
                            return .success(viewModel.mapToAddressBookContactViewModels(
                                addressBookWallet: addressBook,
                                contacts: contacts
                            ))
                        }
                    }
                    .eraseToAnyPublisher()
            }
            .receive(on: DispatchQueue.main)
            .assign(to: &$contactsViewModels)
    }

    func mapToAddressBookContactViewModels(
        addressBookWallet: AddressBookWallet,
        contacts: [AddressBookContact]
    ) -> [AddressBookContactViewModel] {
        contacts.map { contact in
            AddressBookContactViewModel(contact: contact) { [weak self] in
                self?.coordinator?.openEditContact(contact: contact, addressBookWallet: addressBookWallet)
            }
        }
    }
}

// MARK: - Error

private enum AddressBooksLoadError: Error {
    case syncFailed
}
