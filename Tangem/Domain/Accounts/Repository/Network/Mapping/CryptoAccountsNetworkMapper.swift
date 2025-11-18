//
//  CryptoAccountsNetworkMapper.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import struct TangemSdk.DerivationPath

/// Re-uses some logic from `UserTokenListConverter`.
struct CryptoAccountsNetworkMapper {
    typealias RemoteIdentifierBuilder = (StoredCryptoAccount) -> String

    private let supportedBlockchains: SupportedBlockchainsSet
    private let remoteIdentifierBuilder: RemoteIdentifierBuilder

    init(
        supportedBlockchains: SupportedBlockchainsSet,
        remoteIdentifierBuilder: @escaping RemoteIdentifierBuilder
    ) {
        self.supportedBlockchains = supportedBlockchains
        self.remoteIdentifierBuilder = remoteIdentifierBuilder
    }

    // MARK: - Remote to Stored

    func map(response: AccountsDTO.Response.Accounts) -> RemoteCryptoAccountsInfo {
        let grouping = mapGroupingOption(groupType: response.wallet.group)
        let sorting = mapSortingOption(sortType: response.wallet.sort)

        let accounts = response.accounts.map { accountDTO in
            let icon = StoredCryptoAccount.Icon(
                iconName: accountDTO.icon,
                iconColor: accountDTO.iconColor
            )
            let tokens = map(tokens: accountDTO.tokens)

            return StoredCryptoAccount(
                derivationIndex: accountDTO.derivation,
                name: accountDTO.name,
                icon: icon,
                tokens: tokens,
                grouping: grouping,
                sorting: sorting
            )
        }

        let legacyTokens = map(tokens: response.unassignedTokens)
        let nextDerivationIndex = response.wallet.totalAccounts

        if accounts.count != nextDerivationIndex {
            AppLogger.warning(
                String(
                    format: "Back-end inconsistency: incorrect next derivation index: '%d' vs '%d'",
                    nextDerivationIndex,
                    accounts.count
                )
            )
        }

        return RemoteCryptoAccountsInfo(
            nextDerivationIndex: nextDerivationIndex,
            accounts: accounts,
            legacyTokens: legacyTokens
        )
    }

    private func map(tokens: [AccountsDTO.Response.Accounts.Token]) -> [StoredCryptoAccount.Token] {
        var addedTokens: [StoredCryptoAccount.Token.BlockchainNetworkContainer: Set<String>] = [:]

        return tokens
            .compactMap { token in
                guard let blockchainNetworkContainer = try? mapBlockchainNetworkContainer(token: token) else {
                    AppLogger.warning(
                        String(
                            format: "Unable to map token '%@' due to invalid derivation path: '%@'",
                            String(describing: token.id),
                            String(describing: token.derivationPath)
                        )
                    )
                    return nil
                }

                let token = StoredCryptoAccount.Token(
                    id: token.id,
                    name: token.name,
                    symbol: token.symbol,
                    decimalCount: token.decimals,
                    blockchainNetwork: blockchainNetworkContainer,
                    contractAddress: token.contractAddress
                )

                guard let contractAddress = token.contractAddress else {
                    return token
                }

                // Additional uniqueness check for remote tokens (replicates old behavior)
                // Comparison logic here must match the implementation of `Equatable` for `BlockchainSdk.Token`
                if addedTokens[blockchainNetworkContainer, default: []].insert(contractAddress.lowercased()).inserted {
                    return token
                }

                // Duplicate token detected, discarding the duplicate
                AppLogger.warning(
                    String(
                        format: "Duplicate token detected, discarding the duplicate with contract address: '%@'",
                        contractAddress
                    )
                )
                return nil
            }
            .unique() // Additional uniqueness check for remote tokens (replicates old behavior)
    }

    /// - Throws: `HDWalletError` if the derivation path is invalid.
    private func mapBlockchainNetworkContainer(
        token: AccountsDTO.Response.Accounts.Token
    ) throws -> StoredCryptoAccount.Token.BlockchainNetworkContainer {
        // Unknown blockchain
        guard let blockchain = supportedBlockchains[token.networkId] else {
            return .unknown(networkId: token.networkId, rawDerivationPath: token.derivationPath)
        }

        // Known blockchain, but w/o tokens support
        if !blockchain.canHandleTokens, token.contractAddress != nil {
            return .unknown(networkId: token.networkId, rawDerivationPath: token.derivationPath)
        }

        // Mapping must fail here if the derivation path does exist but invalid
        let derivationPath = try token.derivationPath.map(DerivationPath.init(rawPath:))
        let blockchainNetwork = BlockchainNetwork(blockchain, derivationPath: derivationPath)

        return .known(blockchainNetwork: blockchainNetwork)
    }

    private func mapGroupingOption(
        groupType: UserTokenList.GroupType
    ) -> StoredUserTokenList.Grouping {
        switch groupType {
        case .none:
            return .none
        case .network:
            return .byBlockchainNetwork
        }
    }

    private func mapSortingOption(
        sortType: UserTokenList.SortType
    ) -> StoredUserTokenList.Sorting {
        switch sortType {
        case .manual:
            return .manual
        case .balance:
            return .byBalance
        }
    }

    // MARK: - Stored to Remote

    func map(request: [StoredCryptoAccount]) -> AccountsDTO.Request.Accounts {
        let accounts = request
            .map { account in
                let identifier = remoteIdentifierBuilder(account)

                return AccountsDTO.Request.Accounts.Account(
                    id: identifier,
                    name: account.name,
                    icon: account.icon.iconName,
                    iconColor: account.icon.iconColor,
                    derivation: account.derivationIndex
                )
            }

        return AccountsDTO.Request.Accounts(accounts: accounts)
    }

    // MARK: - Archived

    func map(response: AccountsDTO.Response.ArchivedAccounts) -> [ArchivedCryptoAccountInfo] {
        return response.archivedAccounts.compactMap { archivedAccountDTO in
            let accountId = ArchivedCryptoAccountInfo.AccountId(rawValue: archivedAccountDTO.id)
            let rawName = archivedAccountDTO.icon
            let rawColor = archivedAccountDTO.iconColor

            guard let icon = AccountModel.Icon(rawName: rawName, rawColor: rawColor) else {
                AppLogger.warning(
                    String(
                        format: "Unable to map icon: '%@', '%@' for archived account with identifier: '%@'",
                        rawName,
                        rawColor,
                        accountId.rawValue
                    )
                )
                return nil
            }

            guard let name = archivedAccountDTO.name else {
                // Main account (the only account type w/o name) cannot be archived by definition
                AppLogger.warning(
                    String(
                        format: "Unable to map name: '%@' for archived account with identifier: '%@'",
                        String(describing: archivedAccountDTO.name),
                        accountId.rawValue
                    )
                )
                return nil
            }

            return ArchivedCryptoAccountInfo(
                accountId: accountId,
                name: name,
                icon: icon,
                tokensCount: archivedAccountDTO.totalTokens,
                networksCount: archivedAccountDTO.totalNetworks,
                derivationIndex: archivedAccountDTO.derivation
            )
        }
    }
}
