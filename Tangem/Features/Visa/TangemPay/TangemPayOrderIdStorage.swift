//
//  TangemPayOrderIdStorage.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Combine
import Foundation

protocol TangemPayOrderIdStorage {
    func cardIssuingOrderId(customerWalletId: String) -> String?
    func saveCardIssuingOrderId(_ orderId: String, customerWalletId: String)
    func deleteCardIssuingOrderId(customerWalletId: String)
}
