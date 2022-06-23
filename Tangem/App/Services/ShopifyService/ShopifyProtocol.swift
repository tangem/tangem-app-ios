//
//  ShopifyProtocol.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import MobileBuySDK

protocol ShopifyProtocol {
    func cancelTasks()
    func shopName() -> AnyPublisher<String, Error>
    func products(collectionTitleFilter: String?) -> AnyPublisher<[Collection], Error>
    func checkout(pollUntilOrder: Bool, checkoutID: GraphQL.ID) -> AnyPublisher<Checkout, Error>

    func canUseApplePay() -> Bool
    func startApplePaySession(checkoutID: GraphQL.ID) -> AnyPublisher<Checkout, Error>

    func createCheckout(checkoutID: GraphQL.ID?, lineItems: [CheckoutLineItem]) -> AnyPublisher<Checkout, Error>
    func applyDiscount(_ discountCode: String?, checkoutID: GraphQL.ID) -> AnyPublisher<Checkout, Error>
}

private struct ShopifyProtocolKey: InjectionKey {
    static var currentValue: ShopifyProtocol = ShopifyService()
}

extension InjectedValues {
    var shopifyService: ShopifyProtocol {
        get { Self[ShopifyProtocolKey.self] }
        set { Self[ShopifyProtocolKey.self] = newValue }
    }
}
