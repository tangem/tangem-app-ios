//
//  TangemPayOrderIdStorage.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Combine

struct TangemPayOrderIdStorage {
    var savedOrderIdPublisher: AnyPublisher<String?, Never> {
        savedOrderIdSubject.eraseToAnyPublisher()
    }

    private let userDefaults: UserDefaults
    private let customerWalletAddress: String
    private let storageKey: String

    private let savedOrderIdSubject: CurrentValueSubject<String?, Never>

    init(userDefaults: UserDefaults, customerWalletAddress: String) {
        self.userDefaults = userDefaults
        self.customerWalletAddress = customerWalletAddress

        storageKey = "tangem_pay_order_id_for_customer_wallet_address_\(customerWalletAddress)"
        savedOrderIdSubject = CurrentValueSubject(userDefaults.string(forKey: storageKey))
    }

    func saveOrderId(_ orderId: String) {
        userDefaults.set(orderId, forKey: storageKey)
        savedOrderIdSubject.send(orderId)
    }

    func deleteSavedOrderId() {
        if let orderId = userDefaults.string(forKey: storageKey) {
            userDefaults.removeObject(forKey: orderId)
        }
        savedOrderIdSubject.send(nil)
    }
}
