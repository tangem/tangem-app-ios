//
//  WalletConnectSwitchEthereumChainMessageHandler.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import ReownWalletKit
import enum BlockchainSdk.Blockchain

final class WalletConnectSwitchEthereumChainMessageHandler: WalletConnectMessageHandler {
    @Injected(\.userWalletRepository) private var userWalletRepository: any UserWalletRepository

    let method = WalletConnectMethod.switchChain
    let rawTransaction: String? = nil
    let requestData = Data()

    init(requestParams: AnyCodable, connectedDApp: WalletConnectConnectedDApp) throws(WalletConnectTransactionRequestProcessingError) {
        let blockchain = try Self.parseBlockchain(from: requestParams)
        try process(blockchain: blockchain, connectedDApp: connectedDApp)
    }

    func handle() async throws -> JSONRPC.RPCResult {
        assertionFailure("Should never be called. Must be refactored after wiping out old WalletConnect implementation.")
        return JSONRPC.RPCResult.error(.internalError)
    }

    // MARK: - Private methods

    private static func parseBlockchain(
        from requestParams: AnyCodable
    ) throws(WalletConnectTransactionRequestProcessingError) -> BlockchainSdk.Blockchain {
        guard
            let chainIDToValueArray = requestParams.value as? [[String: String]],
            chainIDToValueArray.count == 1,
            let chainIDToValue = chainIDToValueArray.first
        else {
            throw WalletConnectTransactionRequestProcessingError.invalidPayload(requestParams.description)
        }

        guard
            let rawHexChainReference = chainIDToValue["chainId"],
            let caipChainReference = rawHexChainReference.hexToInteger,
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

    private func process(
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

        throw WalletConnectTransactionRequestProcessingError.blockchainToAddRequiresDAppReconnection(blockchain)
    }
}
