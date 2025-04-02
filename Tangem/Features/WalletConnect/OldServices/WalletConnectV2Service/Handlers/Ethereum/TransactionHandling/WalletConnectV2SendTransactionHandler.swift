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
    private let wcTransaction: WalletConnectEthTransaction
    private let walletModel: any WalletModel
    private let transactionBuilder: WalletConnectEthTransactionBuilder
    private let messageComposer: WalletConnectV2MessageComposable
    private let uiDelegate: WalletConnectUIDelegate
    private let transactionDispatcher: TransactionDispatcher
    private let blockaidAPIService: BlockaidAPIService

    private var transactionToSend: Transaction?

    init(
        requestParams: AnyCodable,
        blockchainId: String,
        transactionBuilder: WalletConnectEthTransactionBuilder,
        messageComposer: WalletConnectV2MessageComposable,
        signer: TangemSigner,
        walletModelProvider: WalletConnectWalletModelProvider,
        uiDelegate: WalletConnectUIDelegate,
        blockaidAPIService: BlockaidAPIService
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
        self.uiDelegate = uiDelegate
        self.blockaidAPIService = blockaidAPIService
        transactionDispatcher = SendTransactionDispatcher(walletModel: walletModel, transactionSigner: signer)
    }
}

extension WalletConnectV2SendTransactionHandler: WalletConnectMessageHandler {
    var event: WalletConnectEvent { .sendTx }

    func messageForUser(from dApp: WalletConnectSavedSession.DAppInfo) async throws -> String {
        let transaction = try await transactionBuilder.buildTx(from: wcTransaction, for: walletModel)
        transactionToSend = transaction

        let message = messageComposer.makeMessage(for: transaction, walletModel: walletModel, dApp: dApp)
        return message
    }

    func handle() async throws -> RPCResult {
        guard let transaction = transactionToSend else {
            throw WalletConnectV2Error.missingTransaction
        }
        
        let result = blockaidAPIService.scanEvm(address: transaction.to, blockchain: .ethereum, method: "eth_sendTransaction", transaction: nil, domain: nil)

        let result = try await transactionDispatcher.send(transaction: .transfer(transaction))

        Analytics.log(event: .transactionSent, params: [
            .source: Analytics.ParameterValue.transactionSourceWalletConnect.rawValue,
            .walletForm: result.signerType,
        ])

        uiDelegate.showScreen(with: .init(
            event: .success,
            message: Localization.sendTransactionSuccess,
            approveAction: {}
        ))

        return RPCResult.response(AnyCodable(result.hash))
    }
}
