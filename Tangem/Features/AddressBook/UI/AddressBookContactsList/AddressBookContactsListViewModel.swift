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

    private lazy var wallets: [WalletEntry] = userWalletRepository.models
        .filter { !$0.isUserWalletLocked }
        .map { WalletEntry(id: $0.userWalletId.stringValue, name: $0.name, manager: $0.addressBookManager) }

    init(coordinator: AddressBookContactsListRoutable) {
        self.coordinator = coordinator

        setupChips()
        bind()
    }

    func openAddContact() {
        guard let wallet = selectedWallet else { return }

        coordinator?.openAddContact(addressBookManager: wallet.manager)
    }
}

// MARK: - Private

private extension AddressBookContactsListViewModel {
    var selectedWallet: WalletEntry? {
        wallets.first { $0.id == selectedChipId }
    }

    func setupChips() {
        guard wallets.count >= 2 else {
            walletChips = []
            selectedChipId = wallets.first?.id
            return
        }

        walletChips = wallets.map { Chip(id: $0.id, title: $0.name) }

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
            .compactMap { viewModel, selectedChipId -> WalletEntry? in
                viewModel.wallets.first { $0.id == selectedChipId }
            }
            .withWeakCaptureOf(self)
            .flatMapLatest { viewModel, wallet -> AnyPublisher<[AddressBookContactViewModel], Never> in
                // Trigger a sync for the selected wallet; contactsPublisher then replays the result.
                Task { await wallet.manager.load() }

                return wallet.manager.contactsPublisher
                    .withWeakCaptureOf(viewModel)
                    .map { $0.mapToContactViewModels(wallet: wallet, contacts: $1) }
                    .eraseToAnyPublisher()
            }
            .receive(on: DispatchQueue.main)
            .assign(to: &$contactsViewModels)
    }

    func mapToContactViewModels(wallet: WalletEntry, contacts: [ContactReadModel]) -> [AddressBookContactViewModel] {
        contacts.map { contact in
            AddressBookContactViewModel(contact: contact) { [weak self] in
                guard case .valid(let validContact) = contact else { return }

                self?.coordinator?.openEditContact(addressBookManager: wallet.manager, contact: validContact)
            }
        }
    }
}

// MARK: - Types

extension AddressBookContactsListViewModel {
    struct WalletEntry {
        let id: String
        let name: String
        let manager: AddressBookManager
    }
}
