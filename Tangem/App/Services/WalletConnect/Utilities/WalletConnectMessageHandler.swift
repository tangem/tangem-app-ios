//
//  WalletConnectMessagaHandler.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import WalletConnectUtils

protocol WalletConnectMessageHandler {
    var event: WalletConnectEvent { get }
    func messageForUser(from dApp: WalletConnectSavedSession.DAppInfo) async throws -> String
    func handle() async throws -> RPCResult
}
