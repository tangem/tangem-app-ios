//
//  TangemPayOrderIdStorage.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

public protocol TangemPayOrderIdStorage {
    func deleteCardIssuingOrderId(customerWalletId: String)
}
