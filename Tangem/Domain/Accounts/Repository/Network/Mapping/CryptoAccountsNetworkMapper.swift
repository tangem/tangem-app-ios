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
final class CryptoAccountsNetworkMapper {
    typealias RemoteIdentifierBuilder = (StoredCryptoAccount) -> String

    weak var externalParametersProvider: UserTokenListExternalParametersProvider?

    private let supportedBlockchains: SupportedBlockchainsSet
    private let remoteIdentifierBuilder: RemoteIdentifierBuilder

    init(
        supportedBlockchains: SupportedBlockchainsSet,
        remoteIdentifierBuilder: @escaping RemoteIdentifierBuilder
    ) {
        self.supportedBlockchains = supportedBlockchains
        self.remoteIdentifierBuilder = remoteIdentifierBuilder
    }

    // MARK: - Stored to Remote

    func map(request: [StoredCryptoAccount]) -> (accounts: AccountsDTO.Request.Accounts, userTokens: AccountsDTO.Request.UserTokens) {
        assert(externalParametersProvider != nil, "CryptoAccountsNetworkMapper is not configured with UserTokenListExternalParametersProvider")

        let walletModelAddresses = externalParametersProvider?.provideTokenListAddresses()
        var tokens: [AccountsDTO.Request.Token] = []

        let accounts = request
            .map { account in
                let accountIdentifier = remoteIdentifierBuilder(account)
                let accountTokens = map(
                    tokens: account.tokens,
                    walletModelAddresses: walletModelAddresses,
                    forAccountWithIdentifier: accountIdentifier
                )
                tokens += accountTokens

                return AccountsDTO.Request.Accounts.Account(
                    id: accountIdentifier,
                    name: account.name,
                    icon: account.icon.iconName,
                    iconColor: account.icon.iconColor,
                    derivation: account.derivationIndex
                )
            }

        // Currently, we assume that all accounts share the same grouping option
        let group = mapGroupType(groupingOption: request.first?.grouping)
        // Currently, we assume that all accounts share the same sorting option
        let sort = mapSortType(sortingOption: request.first?.sorting)
        let notifyStatusValue = externalParametersProvider?.provideTokenListNotifyStatusValue()

        let userTokens = AccountsDTO.Request.UserTokens(
            tokens: tokens,
            group: group,
            sort: sort,
            notifyStatus: notifyStatusValue,
            version: Constants.apiVersion
        )

        return (AccountsDTO.Request.Accounts(accounts: accounts), userTokens)
    }

    private func map(
        tokens: [StoredCryptoAccount.Token],
        walletModelAddresses: [WalletModelId: [String]]?,
        forAccountWithIdentifier accountIdentifier: String
    ) -> [AccountsDTO.Request.Token] {
        return tokens
            .map { storedToken in
                let tokenIdentifier = mapTokenId(token: storedToken)
                let networkIdentifier = mapTokenNetworkId(token: storedToken)
                let name = mapTokenName(token: storedToken)
                let derivationPath = mapTokenDerivationPath(token: storedToken)
                let addresses = storedToken.walletModelId.flatMap { walletModelAddresses?[$0] }

                return AccountsDTO.Request.Token(
                    id: tokenIdentifier,
                    accountId: accountIdentifier,
                    networkId: networkIdentifier,
                    name: name,
                    symbol: storedToken.symbol,
                    decimals: storedToken.decimalCount,
                    derivationPath: derivationPath,
                    contractAddress: storedToken.contractAddress,
                    addresses: addresses
                )
            }
    }

    private func mapTokenName(token: StoredCryptoAccount.Token) -> String {
        if token.isToken {
            return token.name
        }

        switch token.blockchainNetwork {
        case .known(let blockchainNetwork):
            return blockchainNetwork.blockchain.coinDisplayName
        case .unknown:
            // [REDACTED_TODO_COMMENT]
            return token.name
        }
    }

    private func mapTokenId(token: StoredCryptoAccount.Token) -> String? {
        if token.isToken {
            return token.id
        }

        switch token.blockchainNetwork {
        case .known(let blockchainNetwork):
            return blockchainNetwork.blockchain.coinId
        case .unknown:
            // [REDACTED_TODO_COMMENT]
            return token.id
        }
    }

    private func mapTokenNetworkId(token: StoredCryptoAccount.Token) -> String {
        switch token.blockchainNetwork {
        case .known(let blockchainNetwork):
            return blockchainNetwork.blockchain.networkId
        case .unknown(let networkId, _):
            return networkId
        }
    }

    private func mapTokenDerivationPath(token: StoredCryptoAccount.Token) -> String? {
        switch token.blockchainNetwork {
        case .known(let blockchainNetwork):
            // Should math the `Codable` implementation of `TangemSdk.DerivationPath`
            return blockchainNetwork.derivationPath?.rawPath
        case .unknown(_, let rawDerivationPath):
            return rawDerivationPath
        }
    }

    private func mapGroupType(
        groupingOption: StoredUserTokenList.Grouping?
    ) -> AccountsDTO.Request.GroupType {
        guard let groupingOption else {
            AccountsLogger.warning("Mapping absent grouping option to a default 'none' group type")
            return .none
        }

        switch groupingOption {
        case .none:
            return .none
        case .byBlockchainNetwork:
            return .network
        }
    }

    private func mapSortType(
        sortingOption: StoredUserTokenList.Sorting?
    ) -> AccountsDTO.Request.SortType {
        guard let sortingOption else {
            AccountsLogger.warning("Mapping absent sorting option to a default 'manual' sort type")
            return .manual
        }

        switch sortingOption {
        case .manual:
            return .manual
        case .byBalance:
            return .balance
        }
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
        let counters = mapCounters(from: response.wallet)

        return RemoteCryptoAccountsInfo(
            counters: counters,
            accounts: accounts,
            legacyTokens: legacyTokens
        )
    }

    private func map(tokens: [AccountsDTO.Response.Accounts.Token]) -> [StoredCryptoAccount.Token] {
        var addedTokens: [StoredCryptoAccount.Token.BlockchainNetworkContainer: Set<String>] = [:]

        return tokens
            .compactMap { token in
                guard let blockchainNetworkContainer = try? mapBlockchainNetworkContainer(token: token) else {
                    AccountsLogger.warning(
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
                AccountsLogger.warning(
                    String(
                        format: "Duplicate token detected, discarding the duplicate with contract address: '%@'",
                        contractAddress
                    )
                )
                return nil
            }
            .unique() // Additional uniqueness check for remote tokens (replicates old behavior)
    }

    private func mapCounters(from wallet: AccountsDTO.Response.Accounts.Wallet) -> RemoteCryptoAccountsInfo.Counters {
        return RemoteCryptoAccountsInfo.Counters(
            archived: wallet.totalArchivedAccounts,
            total: wallet.totalAccounts
        )
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
        groupType: UserTokenList.GroupType?
    ) -> StoredUserTokenList.Grouping {
        guard let groupType else {
            // Fallback value for newly activated wallets (created by the very first PUT /accounts request)
            return CryptoAccountPersistentConfig.TokenListAppearance.default.grouping
        }

        switch groupType {
        case .none:
            return .none
        case .network:
            return .byBlockchainNetwork
        }
    }

    private func mapSortingOption(
        sortType: UserTokenList.SortType?
    ) -> StoredUserTokenList.Sorting {
        guard let sortType else {
            // Fallback value for newly activated wallets (created by the very first PUT /accounts request)
            return CryptoAccountPersistentConfig.TokenListAppearance.default.sorting
        }

        switch sortType {
        case .manual:
            return .manual
        case .balance:
            return .byBalance
        }
    }

    // MARK: - Archived

    func map(response: AccountsDTO.Response.ArchivedAccounts) -> [ArchivedCryptoAccountInfo] {
        return response.archivedAccounts.compactMap { archivedAccountDTO in
            let accountId = ArchivedCryptoAccountInfo.AccountId(rawValue: archivedAccountDTO.id)
            let rawName = archivedAccountDTO.icon
            let rawColor = archivedAccountDTO.iconColor

            guard let icon = AccountModel.Icon(rawName: rawName, rawColor: rawColor) else {
                AccountsLogger.warning(
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
                AccountsLogger.warning(
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

// MARK: - Constants

private extension CryptoAccountsNetworkMapper {
    enum Constants {
        static var apiVersion: Int { 1 }
    }
}
