//
//  SolanaALTTransactionService.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk
import SolanaSwift

public class SolanaALTTransactionService {
    // MARK: - Properties

    private let blockchain: Blockchain
    private let walletPublicKey: Wallet.PublicKey
    private let networkService: SolanaNetworkService
    private let signer: TransactionSigner

    // MARK: - Init

    public init(
        blockchain: Blockchain,
        walletPublicKey: Wallet.PublicKey,
        walletNetworkServiceFactory: WalletNetworkServiceFactory,
        signer: TransactionSigner
    ) throws {
        self.blockchain = blockchain
        self.walletPublicKey = walletPublicKey
        self.signer = signer
        networkService = try walletNetworkServiceFactory.makeServiceWithType(for: blockchain)
    }

    // MARK: - Implementation

    public func send(transactionData: Data) async throws {
        BSDKLogger.debug("ALT: Base64 encoded transaction: \(transactionData.base64EncodedString())")

        guard let publicKey = SolanaSwift.PublicKey(data: walletPublicKey.blockchainKey) else {
            throw BlockchainSdkError.failedToBuildTx
        }

        let solanaSigner = SolanaTransactionSigner(transactionSigner: signer, walletPublicKey: walletPublicKey)

        let transaction: VersionedTransaction

        do {
            transaction = try decodeTransaction(data: transactionData)
        } catch {
            BSDKLogger.error(error: error)
            throw error
        }

        let buildForSend: String

        let lookupTableCreator = SolanaCommonALTLookupTableCreator(networkService: networkService, signer: solanaSigner)
        let blockhashProvider = SolanaCommonALTBlockhashProvider(networkService: networkService)
        let sendBuilder = SolanaCommonALTSendTransactionBuilder(walletPublicKey: publicKey, signer: solanaSigner)
        let accountKeysSplitProvider = SolanaAccountKeysSplitUtils()

        switch transaction.message {
        case .v0(let message):
            let dispatcher = SolanaCommonALTLookupTableDispatcher(
                walletPublicKey: publicKey,
                networkService: networkService,
                lookupTableCreator: lookupTableCreator
            )

            var sender = SolanaALTMessageV0TransactionSender(
                walletPublicKey: publicKey,
                accountKeysSplitProvider: accountKeysSplitProvider,
                sendBuilder: sendBuilder,
                blockhashProvider: blockhashProvider,
                lookupTableDispatcher: dispatcher
            )

            buildForSend = try await sender.buildForSend(message: message)
        case .legacy(let message):
            var sender = SolanaALTLegacyTransactionSender(
                walletPublicKey: publicKey,
                accountKeysSplitProvider: accountKeysSplitProvider,
                sendBuilder: sendBuilder,
                blockhashProvider: blockhashProvider,
                lookupTableCreator: lookupTableCreator
            )

            buildForSend = try await sender.buildForSend(message: message)
        }

        BSDKLogger.debug("ALT: Build for send transaction Base64: \(buildForSend)")

        let transactionId = try await networkService.sendRaw(
            base64serializedTransaction: buildForSend,
            startSendingTimestamp: Date()
        ).async()

        BSDKLogger.info("ALT: [REBUILD] Transaction sent. Transaction ID: \(transactionId)")
    }
}

private extension SolanaALTTransactionService {
    func decodeTransaction(data: Data) throws -> VersionedTransaction {
        try VersionedTransaction.deserialize(data: data)
    }
}
