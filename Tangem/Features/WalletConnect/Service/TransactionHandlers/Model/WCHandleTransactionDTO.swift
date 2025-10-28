//
//  WCHandleTransactionDTO.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import ReownWalletKit
import BlockchainSdk

protocol WCTransactionUpdatable: AnyObject {
    func updateSendableTransaction(_ sendableTransaction: WCSendableTransaction)
}

struct WCHandleTransactionDTO {
    let method: WalletConnectMethod
    let rawTransaction: String?
    let requestData: Data
    let blockchain: BlockchainSdk.Blockchain
    let verificationStatus: WalletConnectDAppVerificationStatus
    let validate: () async throws -> WalletConnectMessageHandleRestrictionType
    let accept: () async throws -> RPCResult
    let reject: () throws -> RPCResult

    weak var updatableHandler: WCTransactionUpdatable?
}
