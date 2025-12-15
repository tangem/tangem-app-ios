//
//  WalletConnectV2SignTransactionHandler.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk
import struct Commons.AnyCodable
import enum JSONRPC.RPCResult

final class WalletConnectV2SignTransactionHandler {
    private var wcTransaction: WalletConnectEthTransaction
    private var sendableTransaction: WCSendableTransaction?
    private let walletModel: any WalletModel
    private let transactionBuilder: WCEthTransactionBuilder
    private let signer: TangemSigner
    private var transaction: Transaction?
    private let request: AnyCodable
    private let encoder = JSONEncoder()

    init(
        requestParams: AnyCodable,
        blockchainId: String,
        transactionBuilder: WCEthTransactionBuilder,
        signer: TangemSigner,
        walletModelProvider: WalletConnectWalletModelProvider
    ) throws {
        do {
            let params = try requestParams.get([WalletConnectEthTransaction].self)
            guard let ethTransaction = params.first else {
                throw WalletConnectTransactionRequestProcessingError.invalidPayload(requestParams.description)
            }

            wcTransaction = ethTransaction
            walletModel = try walletModelProvider.getModel(with: ethTransaction.from, blockchainId: blockchainId)
        } catch {
            WCLogger.error(error: error)
            throw error
        }

        self.transactionBuilder = transactionBuilder
        self.signer = signer
        request = requestParams
    }

    init(
        requestParams: AnyCodable,
        blockchainId: String,
        transactionBuilder: WCEthTransactionBuilder,
        signer: TangemSigner,
        wcAccountsWalletModelProvider: WalletConnectAccountsWalletModelProvider,
        accountId: String
    ) throws {
        do {
            let params = try requestParams.get([WalletConnectEthTransaction].self)

            guard let ethTransaction = params.first else {
                throw WalletConnectTransactionRequestProcessingError.invalidPayload(requestParams.description)
            }

            wcTransaction = ethTransaction

            walletModel = try wcAccountsWalletModelProvider.getModel(
                with: ethTransaction.from,
                blockchainId: blockchainId,
                accountId: accountId
            )

        } catch {
            WCLogger.error(error: error)
            throw error
        }

        self.transactionBuilder = transactionBuilder
        self.signer = signer
        request = requestParams
    }
}

extension WalletConnectV2SignTransactionHandler: WalletConnectMessageHandler, WCTransactionUpdatable {
    var method: WalletConnectMethod { .signTransaction }

    var requestData: Data {
        (try? encoder.encode(wcTransaction)) ?? Data()
    }

    var rawTransaction: String? {
        request.stringRepresentation
    }

    func validate() async throws -> WalletConnectMessageHandleRestrictionType {
        .empty
    }

    func handle() async throws -> RPCResult {
        let transactionToUse = sendableTransaction ?? WCSendableTransaction(from: wcTransaction)
        let transaction = try await transactionBuilder.buildTx(from: transactionToUse, for: walletModel)
        self.transaction = transaction

        guard let ethSigner = walletModel.ethereumTransactionSigner else {
            throw WalletConnectTransactionRequestProcessingError.missingEthTransactionSigner
        }

        async let signedHash = ethSigner.sign(transaction, signer: signer).async()

        return try await .response(AnyCodable(signedHash.lowercased()))
    }

    func updateSendableTransaction(_ updatedSendableTransaction: WCSendableTransaction) {
        sendableTransaction = updatedSendableTransaction
    }
}
