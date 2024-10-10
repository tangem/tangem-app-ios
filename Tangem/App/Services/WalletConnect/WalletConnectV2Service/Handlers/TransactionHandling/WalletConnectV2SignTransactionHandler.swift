//
//  WalletConnectV2SignTransactionHandler.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdkLocal
import struct WalletConnectSwiftV2.AnyCodable
import enum WalletConnectSwiftV2.RPCResult

class WalletConnectV2SignTransactionHandler {
    private let ethTransaction: WalletConnectEthTransaction
    private let walletModel: WalletModel
    private let transactionBuilder: WalletConnectEthTransactionBuilder
    private let messageComposer: WalletConnectV2MessageComposable
    private let signer: TangemSigner
    private var transaction: Transaction?

    init(
        requestParams: AnyCodable,
        blockchainId: String,
        transactionBuilder: WalletConnectEthTransactionBuilder,
        messageComposer: WalletConnectV2MessageComposable,
        signer: TangemSigner,
        walletModelProvider: WalletConnectWalletModelProvider
    ) throws {
        do {
            let params = try requestParams.get([WalletConnectEthTransaction].self)
            guard let ethTransaction = params.first else {
                throw WalletConnectV2Error.notEnoughDataInRequest(requestParams.description)
            }

            self.ethTransaction = ethTransaction
            walletModel = try walletModelProvider.getModel(with: ethTransaction.from, blockchainId: blockchainId)
        } catch {
            AppLog.shared.error(error)
            throw error
        }

        self.transactionBuilder = transactionBuilder
        self.messageComposer = messageComposer
        self.signer = signer
    }
}

extension WalletConnectV2SignTransactionHandler: WalletConnectMessageHandler {
    var event: WalletConnectEvent { .sendTx }

    func messageForUser(from dApp: WalletConnectSavedSession.DAppInfo) async throws -> String {
        let transaction = try await transactionBuilder.buildTx(from: ethTransaction, for: walletModel)
        self.transaction = transaction

        let message = messageComposer.makeMessage(for: transaction, walletModel: walletModel, dApp: dApp)
        return message
    }

    func handle() async throws -> RPCResult {
        guard let ethSigner = walletModel.ethereumTransactionSigner else {
            throw WalletConnectV2Error.missingEthTransactionSigner
        }

        guard let transaction = transaction else {
            throw WalletConnectV2Error.missingTransaction
        }

        async let signedHash = ethSigner.sign(transaction, signer: signer).async()

        return try await .response(AnyCodable(signedHash))
    }
}
