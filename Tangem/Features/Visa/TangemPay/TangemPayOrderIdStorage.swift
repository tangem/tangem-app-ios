//
//  TangemPayOrderIdStorage.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Combine
import Foundation

enum TangemPayOrderIdStorage {
    static func cardIssuingOrderId(customerWalletId: String) -> String? {
        AppSettings.shared.tangemPayCardIssuingOrderIdForCustomerWalletId[customerWalletId]
    }

    static func cardIssuingOrderIdPublisher(customerWalletId: String) -> AnyPublisher<String?, Never> {
        AppSettings.shared.$tangemPayCardIssuingOrderIdForCustomerWalletId
            .map { $0[customerWalletId] }
            .eraseToAnyPublisher()
    }

    static func saveCardIssuingOrderId(_ orderId: String, customerWalletId: String) {
        AppSettings.shared.tangemPayCardIssuingOrderIdForCustomerWalletId[customerWalletId] = orderId
    }

    static func deleteCardIssuingOrderId(customerWalletId: String) {
        AppSettings.shared.tangemPayCardIssuingOrderIdForCustomerWalletId[customerWalletId] = nil
    }
}
