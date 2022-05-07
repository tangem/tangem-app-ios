//
//  ShippingRate.swift
//  TangemShopify
//
//  Created by [REDACTED_AUTHOR]
//

import MobileBuySDK

struct ShippingRate {
    let handle: String
    let title: String
    let amount: Decimal
    
    init(_ shippingRate: Storefront.ShippingRate) {
        self.handle = shippingRate.handle
        self.title = shippingRate.title
        self.amount = shippingRate.priceV2.amount
    }
}

extension ShippingRate {
    var payShippingRate: PayShippingRate {
        PayShippingRate(handle: handle, title: title, price: amount, deliveryRange: nil)
    }
}

extension Storefront.ShippingRateQuery {
    @discardableResult
    func shippingRateFragment() -> Storefront.ShippingRateQuery {
        self
            .handle()
            .title()
            .priceV2 { $0
                .amount()
            }
    }
}
