//
//  NetworkAddressBooksProvider.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import CombineExt
import TangemFoundation

/// Address books scoped to a single network — used by the Send destination and its "View All" screen.
///
/// Each contact keeps only the entries saved on `networkId`; wallets left without contacts are dropped.
/// The same address can be saved in several wallets under different names — every copy is shown, and the
/// wallet name rendered with the contact disambiguates them.
final class NetworkAddressBooksProvider {
    @Injected(\.userWalletRepository)
    private var userWalletRepository: UserWalletRepository

    private let networkId: AddressBookNetworkID

    init(networkId: AddressBookNetworkID) {
        self.networkId = networkId
        loadAddressBooks()
    }
}

// MARK: - AddressBooksProvider

extension NetworkAddressBooksProvider: AddressBooksProvider {
    var addressBooks: [AddressBookWallet] {
        let networkId = networkId
        let perWallet = models().map { model in
            (model, model.addressBookManager.contacts.compactMap { $0.onNetwork(networkId) })
        }
        return makeBooks(from: perWallet)
    }

    var addressBooksPublisher: AnyPublisher<[AddressBookWallet], Never> {
        let models = models()
        guard models.isNotEmpty else {
            return Just([]).eraseToAnyPublisher()
        }

        let networkId = networkId
        return models
            .map { model in
                model.addressBookManager.contactsPublisher
                    .map { (model, $0.compactMap { $0.onNetwork(networkId) }) }
                    .eraseToAnyPublisher()
            }
            .combineLatest()
            .withWeakCaptureOf(self)
            .map { provider, perWallet in provider.makeBooks(from: perWallet) }
            .eraseToAnyPublisher()
    }
}

// MARK: - Helpers

private extension NetworkAddressBooksProvider {
    func models() -> [UserWalletModel] {
        userWalletRepository.models.filter { !$0.isUserWalletLocked }
    }

    func loadAddressBooks() {
        let managers = models().map(\.addressBookManager)
        Task {
            await TaskGroup.executeKeepingOrder(items: managers, action: { manager in
                await manager.load(silent: true)
            })
        }
    }

    func makeBooks(from perWallet: [(UserWalletModel, [AddressBookContact])]) -> [AddressBookWallet] {
        perWallet.compactMap { model, contacts in
            guard contacts.isNotEmpty else {
                return nil
            }

            let manager = model.addressBookManager
            return AddressBookWallet(
                wallet: model.userWalletInfo,
                addressBookManager: manager,
                addressBookPublisher: Just(contacts).eraseToAnyPublisher(),
                syncStatePublisher: manager.syncStatePublisher
            )
        }
    }
}

// MARK: - AddressBookContact + network

private extension AddressBookContact {
    /// Rebuilds the contact keeping only the entries saved on the given network, or `nil` when none remain.
    func onNetwork(_ networkId: AddressBookNetworkID) -> AddressBookContact? {
        let filtered = entries.raw.filter { $0.networkId == networkId }
        guard let entries = AddressBookContactVerifiedEntries(filtered) else {
            return nil
        }

        return AddressBookContact(id: id, walletId: walletId, name: name, appearance: appearance, entries: entries)
    }
}
