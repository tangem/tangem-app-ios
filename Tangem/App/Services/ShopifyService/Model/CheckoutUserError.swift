//
//  CheckoutUserError.swift
//  TangemShopify
//
//  Created by [REDACTED_AUTHOR]
//

import MobileBuySDK

extension Storefront.CheckoutUserErrorQuery {
    @discardableResult
    func checkoutUserErrorFields() -> Storefront.CheckoutUserErrorQuery {
        self
            .field()
            .message()
    }
}
