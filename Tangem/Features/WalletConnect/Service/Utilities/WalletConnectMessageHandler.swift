//
//  WalletConnectMessagaHandler.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import WalletConnectUtils

protocol WalletConnectMessageHandler {
    var method: WalletConnectMethod { get }
    var rawTransaction: String? { get }
    var requestData: Data { get }

    func validate() async throws -> WalletConnectMessageHandleRestrictionType
    func handle() async throws -> RPCResult
}

enum WalletConnectMessageHandleRestrictionType: Identifiable, Equatable {
    case empty
    case multipleTransactions

    var id: String {
        switch self {
        case .empty:
            return "empty"
        case .multipleTransactions:
            return "multipleTransactions"
        }
    }
}
