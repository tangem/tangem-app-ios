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
    let account: (any CryptoAccountModel)?
    let blockchain: BlockchainSdk.Blockchain
    let rawTransaction: String?
    let requestData: Data
    let dAppData: WalletConnectDAppData
    let verificationStatus: WalletConnectDAppVerificationStatus
    let validate: () async throws -> WalletConnectMessageHandleRestrictionType
    let accept: () async throws -> Void
    let reject: () async throws -> Void

    weak var updatableHandler: WCTransactionUpdatable?

    func updateSendableTransaction(_ sendableTransaction: WCSendableTransaction) {
        updatableHandler?.updateSendableTransaction(sendableTransaction)
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
        account = validatedRequest.account
        method = dto.method
        rawTransaction = dto.rawTransaction
        blockchain = dto.blockchain
        requestData = dto.requestData
        verificationStatus = dto.verificationStatus
        dAppData = validatedRequest.dAppData
        updatableHandler = dto.updatableHandler

        validate = {
            try await dto.validate()
        }

        accept = {
            let result = try await dto.accept()
            try await respond(validatedRequest.request.topic, validatedRequest.request.id, result)
        }

        reject = {
            let result = try dto.reject()
            try await respond(validatedRequest.request.topic, validatedRequest.request.id, result)
        }
    }
}
