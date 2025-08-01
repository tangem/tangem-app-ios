//
//  WCHandleTransactionData.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import ReownWalletKit
import BlockchainSdk

struct WCHandleTransactionData {
    let topic: String
    let method: WalletConnectMethod
    let userWalletModel: UserWalletModel
    let blockchain: BlockchainSdk.Blockchain
    let rawTransaction: String?
    let requestData: Data
    let dAppData: WalletConnectDAppData
    let accept: () async throws -> Void
    let reject: () async throws -> Void

    weak var updatableHandler: WCTransactionUpdatable?

    func updateTransaction(_ updatedTransaction: WalletConnectEthTransaction) {
        updatableHandler?.updateTransaction(updatedTransaction)
    }
}

extension WCHandleTransactionData {
    init(
        from dto: WCHandleTransactionDTO,
        validatedRequest: WCValidatedRequest,
        respond: @escaping (String, RPCID, RPCResult) async throws -> Void
    ) {
        topic = validatedRequest.request.topic
        userWalletModel = validatedRequest.userWalletModel
        method = dto.method
        rawTransaction = dto.rawTransaction
        blockchain = dto.blockchain
        requestData = dto.requestData

        dAppData = validatedRequest.dAppData
        updatableHandler = dto.updatableHandler

        accept = {
            let result = try await dto.accept()
            try await respond(validatedRequest.request.topic, validatedRequest.request.id, result)
        }

        reject = {
            let result = try await dto.reject()
            try await respond(validatedRequest.request.topic, validatedRequest.request.id, result)
        }
    }
}
