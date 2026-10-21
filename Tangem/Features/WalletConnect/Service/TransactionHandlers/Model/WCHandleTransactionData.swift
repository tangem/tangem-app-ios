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
    let clearDuplicateFilter: () async -> Void

    weak var updatableHandler: WCTransactionUpdatable?

    func updateSendableTransaction(_ sendableTransaction: WCSendableTransaction) {
        updatableHandler?.updateSendableTransaction(sendableTransaction)
    }
}

extension WCHandleTransactionData {
    init(
        from dto: WCHandleTransactionDTO,
        validatedRequest: WCValidatedRequest,
        respond: @escaping (String, RPCID, RPCResult) async throws -> Void,
        clearDuplicateFilter: @escaping () async -> Void
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

        let request = validatedRequest.request
        let requestDescription = "\(request.method) request \(request.id) on \(request.chainId.absoluteString)"

        accept = {
            let result: RPCResult

            do {
                result = try await dto.accept()
            } catch {
                WCLogger.error("Failed to handle \(requestDescription) on \(dto.blockchain.displayName)", error: error)
                throw error
            }

            WCLogger.info("Accepted \(requestDescription) on \(dto.blockchain.displayName)")
            try await respond(request.topic, request.id, result)
        }

        reject = {
            let result = try dto.reject()
            WCLogger.info("Rejected \(requestDescription) by the user")
            try await respond(request.topic, request.id, result)
        }

        self.clearDuplicateFilter = clearDuplicateFilter
    }
}
