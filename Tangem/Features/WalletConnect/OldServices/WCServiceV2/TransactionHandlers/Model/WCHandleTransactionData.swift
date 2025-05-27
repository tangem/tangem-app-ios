//
//  WCHandleTransactionData.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import ReownWalletKit

struct WCHandleTransactionData {
    let method: WalletConnectMethod
    let userWalletModel: UserWalletModel
    let requestData: Data
    let dappInfo: WalletConnectSavedSession.DAppInfo
    let accept: () async throws -> Void
    let reject: () async throws -> Void
}

extension WCHandleTransactionData {
    init(
        from dto: WCHandleTransactionDTO,
        validatedRequest: WCValidatedRequest,
        respond: @escaping (String, RPCID, RPCResult) async throws -> Void
    ) {
        userWalletModel = validatedRequest.userWalletModel
        method = dto.method
        requestData = dto.requestData

        dappInfo = validatedRequest.session.sessionInfo.dAppInfo

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
