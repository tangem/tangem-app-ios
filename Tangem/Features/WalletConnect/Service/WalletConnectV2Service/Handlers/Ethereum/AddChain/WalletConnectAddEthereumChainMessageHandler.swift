//
//  WalletConnectAddEthereumChainMessageHandler.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import ReownWalletKit
import enum BlockchainSdk.Blockchain

final class WalletConnectAddEthereumChainMessageHandler: WalletConnectMessageHandler {
    @Injected(\.userWalletRepository) private var userWalletRepository: any UserWalletRepository
    @Injected(\.connectedDAppRepository) private var connectedDAppRepository: any WalletConnectConnectedDAppRepository
    @Injected(\.wcService) private var wcService: any WCService

    private let connectedDApp: WalletConnectConnectedDApp
    private let walletModelProvider: any WalletConnectWalletModelProvider
    private let blockchainToAdd: BlockchainSdk.Blockchain

    let method = WalletConnectMethod.addChain
    let rawTransaction: String?
    let requestData: Data

    init(
        requestParams: AnyCodable,
        connectedDApp: WalletConnectConnectedDApp,
        walletModelProvider: some WalletConnectWalletModelProvider
    ) throws(WalletConnectTransactionRequestProcessingError) {
        self.connectedDApp = connectedDApp
        self.walletModelProvider = walletModelProvider

        rawTransaction = requestParams.stringRepresentation
        requestData = try Self.makeRequestData(from: requestParams)
        blockchainToAdd = try Self.parseBlockchain(from: requestParams)

        try validate(blockchain: blockchainToAdd, connectedDApp: connectedDApp)
    }

    func handle() async throws -> JSONRPC.RPCResult {
        guard let reownBlockchainToAdd = WalletConnectBlockchainMapper.mapFromDomain(blockchainToAdd) else {
            throw WalletConnectTransactionRequestProcessingError.invalidPayload("Blockchain mapping error. Developer mistake.")
        }

        let reownAccountsToAdd = WalletConnectAccountsMapper.map(
            from: blockchainToAdd,
            walletConnectWalletModelProvider: walletModelProvider,
            preferredCAIPReference: nil
        )

        var reownNamespacesToUpdate = WalletConnectSessionNamespaceMapper.mapFromDomain(connectedDApp.session.namespaces)
        var reownNamespaceToUpdate = reownNamespacesToUpdate[WalletConnectSupportedNamespace.eip155.rawValue]
        reownNamespaceToUpdate?.chains?.insert(reownBlockchainToAdd)
        reownNamespaceToUpdate?.accounts.append(contentsOf: reownAccountsToAdd)

        reownNamespacesToUpdate[WalletConnectSupportedNamespace.eip155.rawValue] = reownNamespaceToUpdate

        try await wcService.updateSession(withTopic: connectedDApp.session.topic, namespaces: reownNamespacesToUpdate)

        let updatedConnectedDApp = connectedDApp.with(
            addedBlockchain: blockchainToAdd,
            updatedNamespaces: WalletConnectSessionNamespaceMapper.mapToDomain(reownNamespacesToUpdate)
        )

        try await connectedDAppRepository.replaceExistingDApp(with: updatedConnectedDApp)

        let emptyResponse = AnyCodable("")
        return JSONRPC.RPCResult.response(emptyResponse)
    }

    // MARK: - Private methods

    private static func makeRequestData(from requestParams: AnyCodable) throws(WalletConnectTransactionRequestProcessingError) -> Data {
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
            return try encoder.encode(requestParams)
        } catch {
            throw WalletConnectTransactionRequestProcessingError.invalidPayload(requestParams.description)
        }
    }

    private static func parseBlockchain(
        from requestParams: AnyCodable
    ) throws(WalletConnectTransactionRequestProcessingError) -> BlockchainSdk.Blockchain {
        guard
            let requestParamsEntries = try? requestParams.get([RequestParameterEntry].self),
            requestParamsEntries.count == 1,
            let entry = requestParamsEntries.first
        else {
            throw WalletConnectTransactionRequestProcessingError.invalidPayload(requestParams.description)
        }

        guard
            let caipChainReference = entry.chainId.hexToInteger,
            let reownBlockchain = ReownWalletKit.Blockchain(
                namespace: WalletConnectSupportedNamespace.eip155.rawValue,
                reference: String(caipChainReference)
            )
        else {
            throw WalletConnectTransactionRequestProcessingError.invalidPayload(requestParams.description)
        }

        guard let domainBlockchain = WalletConnectBlockchainMapper.mapToDomain(reownBlockchain) else {
            throw WalletConnectTransactionRequestProcessingError.unsupportedBlockchain(reownBlockchain.absoluteString)
        }

        return domainBlockchain
    }

    private func validate(
        blockchain: BlockchainSdk.Blockchain,
        connectedDApp: WalletConnectConnectedDApp
    ) throws(WalletConnectTransactionRequestProcessingError) {
        guard !connectedDApp.dAppBlockchains.map(\.blockchain.networkId).contains(blockchain.networkId) else {
            throw WalletConnectTransactionRequestProcessingError.blockchainToAddDuplicate(blockchain)
        }

        guard
            let userWallet = userWalletRepository.models.first(where: { $0.userWalletId.stringValue == connectedDApp.userWalletID }),
            !userWallet.isUserWalletLocked
        else {
            throw WalletConnectTransactionRequestProcessingError.userWalletNotFound
        }

        guard userWallet
            .userTokenListManager
            .userTokensList
            .entries
            .contains(where: { $0.blockchainNetwork.blockchain.networkId == blockchain.networkId })
        else {
            throw WalletConnectTransactionRequestProcessingError.blockchainToAddIsMissingFromUserWallet(blockchain)
        }
    }
}

// MARK: - Nested types

extension WalletConnectAddEthereumChainMessageHandler {
    private struct RequestParameterEntry: Codable {
        let chainId: String
        let blockExplorerUrls: [String]
        let nativeCurrency: NativeCurrency
        let chainName: String
        let rpcUrls: [String]

        struct NativeCurrency: Codable {
            let decimals: Int
            let name: String
            let symbol: String
        }
    }
}

private extension WalletConnectConnectedDApp {
    func with(
        addedBlockchain: BlockchainSdk.Blockchain,
        updatedNamespaces: [String: WalletConnectSessionNamespace]
    ) -> WalletConnectConnectedDApp {
        WalletConnectConnectedDApp(
            session: WalletConnectDAppSession(
                topic: session.topic,
                namespaces: updatedNamespaces,
                expiryDate: session.expiryDate
            ),
            userWalletID: userWalletID,
            dAppData: dAppData,
            verificationStatus: verificationStatus,
            dAppBlockchains: dAppBlockchains + [WalletConnectDAppBlockchain(blockchain: addedBlockchain, isRequired: false)],
            connectionDate: connectionDate
        )
    }
}
