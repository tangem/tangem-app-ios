//
//  WalletConnectV2SendTransactionHandler.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import TangemLocalization
import BlockchainSdk
import struct Commons.AnyCodable
import enum JSONRPC.RPCResult

class WalletConnectV2SendTransactionHandler {
    private var wcTransaction: WalletConnectEthTransaction
    private var sendableTransaction: WCSendableTransaction?
    private let walletModel: any WalletModel
    private let transactionBuilder: WCEthTransactionBuilder
    private let transactionDispatcher: TransactionDispatcher
    private let request: AnyCodable
    private let encoder = JSONEncoder()

    private var transactionToSend: Transaction?

    init(
        requestParams: AnyCodable,
        blockchainId: String,
        transactionBuilder: WCEthTransactionBuilder,
        signer: TangemSigner,
        walletModelProvider: WalletConnectWalletModelProvider,
    ) throws {
        do {
            let params = try requestParams.get([WalletConnectEthTransaction].self)

            guard let wcTransaction = params.first else {
                throw WalletConnectTransactionRequestProcessingError.invalidPayload(requestParams.description)
            }

            self.wcTransaction = wcTransaction
            walletModel = try walletModelProvider.getModel(with: wcTransaction.from, blockchainId: blockchainId)
        } catch {
            WCLogger.error("Failed to create Send transaction handler", error: error)
            throw error
        }

        self.transactionBuilder = transactionBuilder
        transactionDispatcher = TransactionDispatcherFactory(walletModel: walletModel, signer: signer).makeSendDispatcher()
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

            guard let wcTransaction = params.first else {
                throw WalletConnectTransactionRequestProcessingError.invalidPayload(requestParams.description)
            }

            self.wcTransaction = wcTransaction

            walletModel = try wcAccountsWalletModelProvider.getModel(
                with: wcTransaction.from,
                blockchainId: blockchainId,
                accountId: accountId
            )
        } catch {
            WCLogger.error("Failed to create Send transaction handler", error: error)
            throw error
        }

        self.transactionBuilder = transactionBuilder
        transactionDispatcher = TransactionDispatcherFactory(walletModel: walletModel, signer: signer).makeSendDispatcher()
        request = requestParams
    }
}

extension WalletConnectV2SendTransactionHandler: WalletConnectMessageHandler, WCTransactionUpdatable {
    var method: WalletConnectMethod { .sendTransaction }

    var requestData: Data {
        return (try? encoder.encode(wcTransaction)) ?? Data()
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
        transactionToSend = transaction

        guard let transaction = transactionToSend else {
            throw WalletConnectTransactionRequestProcessingError.invalidPayload("Transaction is missing.")
        }

        let result = try await transactionDispatcher.send(transaction: .transfer(transaction))

        Analytics.log(event: .transactionSent, params: [
            .source: Analytics.ParameterValue.transactionSourceWalletConnect.rawValue,
            .token: SendAnalyticsHelper.makeAnalyticsTokenName(from: walletModel.tokenItem),
            .blockchain: walletModel.tokenItem.blockchain.displayName,
            .walletForm: result.signerType,
            .selectedHost: result.currentHost,
        ])

        return RPCResult.response(AnyCodable(result.hash.lowercased()))
    }

    func updateTransaction(_ updatedTransaction: WalletConnectEthTransaction) {
        wcTransaction = updatedTransaction
        transactionToSend = nil
    }

    func updateSendableTransaction(_ updatedSendableTransaction: WCSendableTransaction) {
        sendableTransaction = updatedSendableTransaction
    }
}
