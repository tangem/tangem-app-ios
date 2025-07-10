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
    var event: WalletConnectEvent { get }
    var rawTransaction: String? { get }
    var requestData: Data { get }
    func messageForUser(from dApp: WalletConnectSavedSession.DAppInfo) async throws -> String
    func handle() async throws -> RPCResult
}
