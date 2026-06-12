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
    @Published private(set) var contacts: [AddressBookContact] = []

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
        coordinator?.openAddContact()
    }
}

// MARK: - Private

private extension AddressBookContactsListViewModel {
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
            .map { [addressBooks] selectedId -> AnyPublisher<[AddressBookContact], Never> in
                guard let addressBook = addressBooks.first(where: { $0.wallet.id.stringValue == selectedId }) else {
                    return Just([]).eraseToAnyPublisher()
                }

                return addressBook.addressBookPublisher.map(\.contacts).eraseToAnyPublisher()
            }
            .switchToLatest()
            .receive(on: DispatchQueue.main)
            .assign(to: &$contacts)
    }
}
