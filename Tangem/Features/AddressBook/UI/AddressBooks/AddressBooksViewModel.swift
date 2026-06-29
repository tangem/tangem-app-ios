//
//  AddressBooksViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import CombineExt
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
    private let addressBooksSubject: CurrentValueSubject<[AddressBookWallet], Never>
    private var bag = Set<AnyCancellable>()

    init(
        coordinator: AddressBooksRoutable,
        addressBooksProvider: any AddressBooksProvider = .common()
    ) {
        self.coordinator = coordinator
        self.addressBooksProvider = addressBooksProvider
        addressBooksSubject = .init(addressBooksProvider.addressBooks)
        selectedChipId = defaultSelectedChipId

        bindAddressBooks()
        bind()
        bindChips()
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
        addressBooksSubject.value.first { $0.wallet.id.stringValue == selectedChipId }
    }

    var defaultSelectedChipId: String? {
        userWalletRepository.selectedModel?.userWalletId.stringValue ?? addressBooksSubject.value.first?.wallet.id.stringValue
    }

    func bindAddressBooks() {
        addressBooksProvider.addressBooksPublisher
            .dropFirst() // the subject is already seeded with the initial set
            .withWeakCaptureOf(self)
            .sink { viewModel, addressBooks in
                viewModel.addressBooksSubject.send(addressBooks)
            }
            .store(in: &bag)
    }

    func bindChips() {
        addressBooksSubject
            .flatMapLatest { addressBooks -> AnyPublisher<[String: Bool], Never> in
                guard addressBooks.isNotEmpty else {
                    return Just([:]).eraseToAnyPublisher()
                }

                let nonEmptyFlags = addressBooks.map { addressBook in
                    addressBook.addressBookPublisher
                        .map { (id: addressBook.wallet.id.stringValue, hasContacts: $0.isNotEmpty) }
                        .eraseToAnyPublisher()
                }

                return nonEmptyFlags
                    .combineLatest()
                    .map { flags in Dictionary(uniqueKeysWithValues: flags.map { ($0.id, $0.hasContacts) }) }
                    .eraseToAnyPublisher()
            }
            .receiveOnMain()
            .withWeakCaptureOf(self)
            .sink { viewModel, nonEmptyById in
                viewModel.applyChips(nonEmptyById: nonEmptyById)
            }
            .store(in: &bag)
    }

    func applyChips(nonEmptyById: [String: Bool]) {
        let nonEmptyBooks = addressBooksSubject.value.filter { nonEmptyById[$0.wallet.id.stringValue] == true }
        walletChips = nonEmptyBooks.map { Chip(id: $0.wallet.id.stringValue, title: $0.wallet.name) }

        if let selectedChipId, nonEmptyById[selectedChipId] == true {
            return
        }

        let nonEmptyIds = Set(nonEmptyBooks.map { $0.wallet.id.stringValue })
        if let currentWalletId = userWalletRepository.selectedModel?.userWalletId.stringValue, nonEmptyIds.contains(currentWalletId) {
            selectedChipId = currentWalletId
        } else if let firstNonEmptyId = nonEmptyBooks.first?.wallet.id.stringValue {
            selectedChipId = firstNonEmptyId
        } else {
            selectedChipId = defaultSelectedChipId
        }
    }

    func bind() {
        Publishers.CombineLatest($selectedChipId, addressBooksSubject)
            .map { selectedChipId, addressBooks -> AddressBookWallet? in
                addressBooks.first(where: { $0.wallet.id.stringValue == selectedChipId })
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
            .receiveOnMain()
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
