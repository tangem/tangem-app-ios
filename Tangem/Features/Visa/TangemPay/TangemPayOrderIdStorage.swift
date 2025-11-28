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
    static func cardIssuingOrderId(customerWalletAddress: String) -> String? {
        AppSettings.shared.tangemPayCardIssuingOrderIdForCustomerWalletAddress[customerWalletAddress]
    }

    static func cardIssuingOrderIdPublisher(customerWalletAddress: String) -> AnyPublisher<String?, Never> {
        AppSettings.shared.$tangemPayCardIssuingOrderIdForCustomerWalletAddress
            .map { $0[customerWalletAddress] }
            .eraseToAnyPublisher()
    }

    static func saveCardIssuingOrderId(_ orderId: String, customerWalletAddress: String) {
        AppSettings.shared.tangemPayCardIssuingOrderIdForCustomerWalletAddress[customerWalletAddress] = orderId
    }

    static func deleteCardIssuingOrderId(customerWalletAddress: String) {
        AppSettings.shared.tangemPayCardIssuingOrderIdForCustomerWalletAddress[customerWalletAddress] = nil
    }
}
