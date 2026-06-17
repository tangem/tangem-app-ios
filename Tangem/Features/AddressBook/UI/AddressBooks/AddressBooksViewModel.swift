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
    @Published private(set) var contactsViewModels: LoadingResult<[AddressBookContactViewModel], Never> = .loading

    // MARK: - Dependencies

    @Injected(\.userWalletRepository)
    private var userWalletRepository: UserWalletRepository

    private weak var coordinator: AddressBooksRoutable?
    private let addressBooksProvider: any AddressBooksProvider
    private let addressBooks: [AddressBookWallet]

    init(
        coordinator: AddressBooksRoutable,
        addressBooksProvider: any AddressBooksProvider = .mock()
    ) {
        self.coordinator = coordinator
        self.addressBooksProvider = addressBooksProvider
        addressBooks = addressBooksProvider.addressBooks

        setupChips()
        bind()
    }

    func openAddContact() {
        coordinator?.openAddContact()
    }
}

// MARK: - Private

private extension AddressBooksViewModel {
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
            .flatMapLatest { viewModel, addressBook -> AnyPublisher<LoadingResult<[AddressBookContactViewModel], Never>, Never> in
                guard let addressBook else {
                    return Just(.success([])).eraseToAnyPublisher()
                }

                return addressBook.addressBookPublisher
                    .withWeakCaptureOf(viewModel)
                    .map { .success($0.mapToAddressBookContactViewModels(contacts: $1.contacts)) }
                    .eraseToAnyPublisher()
            }
            .receive(on: DispatchQueue.main)
            .assign(to: &$contactsViewModels)
    }

    func mapToAddressBookContactViewModels(contacts: [AddressBookContact]) -> [AddressBookContactViewModel] {
        contacts.map { contact in
            AddressBookContactViewModel(contact: contact) { [weak self] in
                self?.coordinator?.openEditContact(contact: contact)
            }
        }
    }
}
