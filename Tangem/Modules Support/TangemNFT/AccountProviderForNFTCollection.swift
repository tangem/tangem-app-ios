//
//  AccountProviderForNFTCollection.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import TangemNFT
import Combine

final class AccountForNFTCollectionProvider {
    private let accountModelsManager: AccountModelsManager
    private var cryptoAccounts: CryptoAccounts?

    /// Cached mapping:  address -> crypto account
    /// Built lazily on first call to provideAccountsWithCollectionsState
    private var addressToAccountMap: [String: any CryptoAccountModel]?
    private var bag = Set<AnyCancellable>()

    init(accountModelsManager: AccountModelsManager) {
        self.accountModelsManager = accountModelsManager

        bind()
    }

    private func bind() {
        accountModelsManager.accountModelsPublisher
            .compactMap(\.first)
            .withWeakCaptureOf(self)
            .sink { viewModel, accountModel in
                if case .standard(let cryptoAccounts) = accountModel {
                    viewModel.cryptoAccounts = cryptoAccounts
                    // Invalidate cache when accounts change
                    viewModel.addressToAccountMap = nil
                }
            }
            .store(in: &bag)
    }

    private func buildAddressToAccountMap(for accounts: [any CryptoAccountModel]) -> [String: any CryptoAccountModel] {
        var map: [String: any CryptoAccountModel] = [:]

        for account in accounts {
            let walletModels = account.walletModelsManager.walletModels

            for walletModel in walletModels {
                for address in walletModel.addresses {
                    map[address.value] = account
                }
            }
        }

        return map
    }

    private func groupCollectionsByAccount(
        collections: [NFTCollection],
        addressMap: [String: any CryptoAccountModel]
    ) -> [AnyHashable: (account: any CryptoAccountModel, collections: [NFTCollection])] {
        var accountToCollections: [AnyHashable: (account: any CryptoAccountModel, collections: [NFTCollection])] = [:]

        for collection in collections {
            guard let account = addressMap[collection.id.ownerAddress] else {
                continue
            }

            let accountId = account.id.toAnyHashable()

            if accountToCollections[accountId] != nil {
                accountToCollections[accountId]?.collections.append(collection)
            } else {
                accountToCollections[accountId] = (account: account, collections: [collection])
            }
        }

        return accountToCollections
    }

    private func buildAccountsWithCollectionsData(
        accountIDs: [AnyHashable],
        accountToCollections: [AnyHashable: (account: any CryptoAccountModel, collections: [NFTCollection])]
    ) -> [AccountWithCollectionsData] {
        accountIDs.compactMap { accountId in
            guard let tuple = accountToCollections[accountId] else {
                return nil
            }

            let iconData = AccountModelUtils.UI.iconViewData(accountModel: tuple.account)
            let accountData = AccountForNFTData(
                id: accountId,
                iconData: iconData,
                name: tuple.account.name
            )

            return AccountWithCollectionsData(
                accountData: accountData,
                collections: tuple.collections
            )
        }
    }
}

extension AccountForNFTCollectionProvider: AccountForNFTCollectionProviding {
    func provideAccountsWithCollectionsState(for collections: [NFTCollection]) -> AccountsWithCollectionsState {
        guard let cryptoAccounts else {
            return .singleAccount
        }

        switch cryptoAccounts {
        case .single:
            return .singleAccount

        case .multiple(let accounts):
            // Build address lookup map if needed
            if addressToAccountMap == nil {
                addressToAccountMap = buildAddressToAccountMap(for: accounts)
            }

            guard let addressMap = addressToAccountMap else {
                return .singleAccount
            }

            // Group collections by their owner accounts
            let accountToCollections = groupCollectionsByAccount(
                collections: collections,
                addressMap: addressMap
            )

            // Build result maintaining original account order
            let accountIDs = accounts.map { $0.id.toAnyHashable() }
            let accountsWithCollections = buildAccountsWithCollectionsData(
                accountIDs: accountIDs,
                accountToCollections: accountToCollections
            )

            return .multipleAccounts(accountsWithCollections)
        }
    }
}
