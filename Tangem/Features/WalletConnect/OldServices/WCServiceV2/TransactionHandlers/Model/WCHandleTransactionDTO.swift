//
//  WCHandleTransactionDTO.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import ReownWalletKit

struct WCHandleTransactionDTO {
    let method: WalletConnectMethod
    let requestData: Data
    let accept: () async throws -> RPCResult
    let reject: () async throws -> RPCResult
}
