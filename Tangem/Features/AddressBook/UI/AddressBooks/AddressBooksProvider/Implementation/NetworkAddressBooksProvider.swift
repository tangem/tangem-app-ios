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
/// Each contact keeps only the entries saved on `networkId`. Since a contact name is unique only within a
/// `walletId`, the same address can appear under different names across wallets; per spec 1.3.1 the list is
/// de-duplicated by address, keeping the contact from the send wallet (`currentWalletId`) on a collision so
/// its name is the one shown. Wallets left without contacts are dropped.
final class NetworkAddressBooksProvider {
    @Injected(\.userWalletRepository)
    private var userWalletRepository: UserWalletRepository

    private let networkId: AddressBookNetworkID
    private let currentWalletId: UserWalletId

    init(networkId: AddressBookNetworkID, currentWalletId: UserWalletId) {
        self.networkId = networkId
        self.currentWalletId = currentWalletId
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
        return makeDedupedBooks(from: perWallet)
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
            .map { provider, perWallet in provider.makeDedupedBooks(from: perWallet) }
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
                await manager.load()
            })
        }
    }

    /// De-duplicates contacts by their address set across wallets, keeping the copy from the send wallet on a
    /// collision so its name wins. Wallets left with no contacts afterwards are dropped.
    func makeDedupedBooks(from perWallet: [(UserWalletModel, [AddressBookContact])]) -> [AddressBookWallet] {
        let currentWalletId = currentWalletId.stringValue
        var owner: [String: String] = [:]

        for (model, contacts) in perWallet {
            let walletId = model.userWalletInfo.id.stringValue
            for contact in contacts {
                let key = Self.addressKey(contact)
                switch owner[key] {
                case .none:
                    owner[key] = walletId
                case .some(let existing) where existing != currentWalletId && walletId == currentWalletId:
                    owner[key] = walletId
                case .some:
                    break
                }
            }
        }

        return perWallet.compactMap { model, contacts in
            let walletId = model.userWalletInfo.id.stringValue
            let kept = contacts.filter { owner[Self.addressKey($0)] == walletId }
            guard kept.isNotEmpty else {
                return nil
            }

            let manager = model.addressBookManager
            return AddressBookWallet(
                wallet: model.userWalletInfo,
                addressBookManager: manager,
                addressBookPublisher: Just(kept).eraseToAnyPublisher(),
                syncStatePublisher: manager.syncStatePublisher
            )
        }
    }

    static func addressKey(_ contact: AddressBookContact) -> String {
        Set(contact.entries.raw.map { $0.address.lowercased() }).sorted().joined(separator: "|")
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
