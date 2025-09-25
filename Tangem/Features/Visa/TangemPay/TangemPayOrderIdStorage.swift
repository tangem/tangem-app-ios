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
    let savedOrderIdPublisher: AnyPublisher<String?, Never>

    private let appSettings: AppSettings
    private let customerWalletAddress: String

    init(customerWalletAddress: String, appSettings: AppSettings) {
        self.customerWalletAddress = customerWalletAddress
        self.appSettings = appSettings

        savedOrderIdPublisher = appSettings.$tangemPayOrderIdForCustomerWalletAddress
            .map { $0[customerWalletAddress] }
            .eraseToAnyPublisher()
    }

    func saveOrderId(_ orderId: String) {
        appSettings.tangemPayOrderIdForCustomerWalletAddress[customerWalletAddress] = orderId
    }

    func deleteSavedOrderId() {
        appSettings.tangemPayOrderIdForCustomerWalletAddress[customerWalletAddress] = nil
    }
}
