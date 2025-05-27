//
//  WCTransactionRoutable.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

protocol WCTransactionRoutable {
    func showWCTransactionRequest(with data: WCHandleTransactionData)
    func showWCTransactionRequest(with error: Error)
}
