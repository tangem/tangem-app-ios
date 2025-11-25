//
//  TangemPayOrderIdStorage.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Combine
import Foundation

struct TangemPayOrderIdStorage {
    let cardIssuingOrderIdPublisher: AnyPublisher<String?, Never>
    var cardIssuingOrderId: String? {
        appSettings.tangemPayCardIssuingOrderIdForCustomerWalletAddress[customerWalletAddress]
    }

    private let appSettings: AppSettings
    private let customerWalletAddress: String

    init(customerWalletAddress: String, appSettings: AppSettings) {
        self.customerWalletAddress = customerWalletAddress
        self.appSettings = appSettings

        cardIssuingOrderIdPublisher = appSettings.$tangemPayCardIssuingOrderIdForCustomerWalletAddress
            .map { $0[customerWalletAddress] }
            .eraseToAnyPublisher()
    }

    func saveCardIssuingOrderId(_ orderId: String) {
        appSettings.tangemPayCardIssuingOrderIdForCustomerWalletAddress[customerWalletAddress] = orderId
    }

    func deleteCardIssuingOrderId() {
        appSettings.tangemPayCardIssuingOrderIdForCustomerWalletAddress[customerWalletAddress] = nil
    }
}
