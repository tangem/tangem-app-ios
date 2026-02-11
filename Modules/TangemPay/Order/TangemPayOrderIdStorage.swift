//
//  TangemPayOrderIdStorage.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

public protocol TangemPayOrderIdStorage {
    func cardIssuingOrderId(customerWalletId: String) -> String?
    func saveCardIssuingOrderId(_ orderId: String, customerWalletId: String)
    func deleteCardIssuingOrderId(customerWalletId: String)
}
