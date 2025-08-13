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
    private let transactionBuilder: WalletConnectEthTransactionBuilder
    private let newEthTransactionBuilder: WCNewEthTransactionBuilder
    private let messageComposer: WalletConnectV2MessageComposable
    private let uiDelegate: WalletConnectUIDelegate
    private let transactionDispatcher: TransactionDispatcher
    private let request: AnyCodable
    private let encoder = JSONEncoder()

    private var transactionToSend: Transaction?

    init(
        requestParams: AnyCodable,
        blockchainId: String,
        transactionBuilder: WalletConnectEthTransactionBuilder,
        newEthTransactionBuilder: WCNewEthTransactionBuilder,
        messageComposer: WalletConnectV2MessageComposable,
        signer: TangemSigner,
        walletModelProvider: WalletConnectWalletModelProvider,
        uiDelegate: WalletConnectUIDelegate
    ) throws {
        do {
            let params = try requestParams.get([WalletConnectEthTransaction].self)

            guard let wcTransaction = params.first else {
                throw WalletConnectV2Error.missingTransaction
            }

            self.wcTransaction = wcTransaction
            walletModel = try walletModelProvider.getModel(with: wcTransaction.from, blockchainId: blockchainId)
        } catch {
            WCLogger.error("Failed to create Send transaction handler", error: error)
            throw error
        }

        self.messageComposer = messageComposer
        self.transactionBuilder = transactionBuilder
        self.newEthTransactionBuilder = newEthTransactionBuilder
        self.uiDelegate = uiDelegate
        transactionDispatcher = SendTransactionDispatcher(walletModel: walletModel, transactionSigner: signer)
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

    var event: WalletConnectEvent { .sendTx }

    func messageForUser(from dApp: WalletConnectSavedSession.DAppInfo) async throws -> String {
        let transaction = try await transactionBuilder.buildTx(from: wcTransaction, for: walletModel)
        transactionToSend = transaction

        let message = messageComposer.makeMessage(for: transaction, walletModel: walletModel, dApp: dApp)
        return message
    }

    func handle() async throws -> RPCResult {
        if FeatureProvider.isAvailable(.walletConnectUI) {
            let transactionToUse = sendableTransaction ?? WCSendableTransaction(from: wcTransaction)
            let transaction = try await newEthTransactionBuilder.buildTx(from: transactionToUse, for: walletModel)
            transactionToSend = transaction
        }
        guard let transaction = transactionToSend else {
            throw WalletConnectV2Error.missingTransaction
        }

        let result = try await transactionDispatcher.send(transaction: .transfer(transaction))

        Analytics.log(event: .transactionSent, params: [
            .source: Analytics.ParameterValue.transactionSourceWalletConnect.rawValue,
            .token: walletModel.tokenItem.currencySymbol,
            .blockchain: walletModel.tokenItem.blockchain.displayName,
            .walletForm: result.signerType,
        ])

        if !FeatureProvider.isAvailable(.walletConnectUI) {
            uiDelegate.showScreen(with: .init(
                event: .success,
                message: Localization.sendTransactionSuccess,
                approveAction: {}
            ))
        }

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
