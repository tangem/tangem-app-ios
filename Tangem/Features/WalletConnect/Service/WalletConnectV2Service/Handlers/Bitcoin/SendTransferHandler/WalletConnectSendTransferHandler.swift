//
//  WalletConnectSendTransferHandler.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk
import struct Commons.AnyCodable
import enum JSONRPC.RPCResult

class WalletConnectSendTransferHandler {
    private var wcTransaction: WalletConnectBtcTransaction
    private var sendableTransaction: WalletConnectBtcTransaction?
    private var transactionBuilder: WCBtcTransactionBuilder
    private let transactionDispatcher: TransactionDispatcher
    private let walletModel: any WalletModel
    private let request: AnyCodable
    private let encoder = JSONEncoder()

    private var transactionToSend: Transaction?

    init(
        requestParams: AnyCodable,
        blockchainId: String,
        transactionBuilder: WCBtcTransactionBuilder,
        signer: TangemSigner,
        walletModelProvider: WalletConnectWalletModelProvider
    ) throws {
        do {
            let wcTransaction = try requestParams.get(WalletConnectBtcTransaction.self)

            self.wcTransaction = wcTransaction
            walletModel = try walletModelProvider.getModel(with: wcTransaction.account, blockchainId: blockchainId)
        } catch {
            WCLogger.error("Failed to create Send transfer handler", error: error)
            throw WalletConnectTransactionRequestProcessingError.invalidPayload(requestParams.description)
        }

        self.transactionBuilder = transactionBuilder
        transactionDispatcher = SendTransactionDispatcher(walletModel: walletModel, transactionSigner: signer)
        request = requestParams
    }
}

extension WalletConnectSendTransferHandler: WalletConnectMessageHandler {
    var method: WalletConnectMethod {
        .sendTransfer
    }

    var rawTransaction: String? {
        request.stringRepresentation
    }

    var requestData: Data {
        return (try? encoder.encode(wcTransaction)) ?? Data()
    }

    func validate() async throws -> WalletConnectMessageHandleRestrictionType {
        .empty
    }

    func handle() async throws -> RPCResult {
        let transactionToUse = sendableTransaction ?? wcTransaction
        let transaction = try await transactionBuilder.buildTx(from: transactionToUse, for: walletModel)
        transactionToSend = transaction

        guard let transaction = transactionToSend else {
            throw WalletConnectTransactionRequestProcessingError.invalidPayload("Transaction is missing.")
        }

        let result = try await transactionDispatcher.send(transaction: .transfer(transaction))

        return .response(AnyCodable(result.hash.lowercased()))
    }
}
