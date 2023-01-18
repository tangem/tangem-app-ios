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
        handle = shippingRate.handle
        title = shippingRate.title
        amount = shippingRate.priceV2.amount
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
        handle()
            .title()
            .priceV2 { $0
                .amount()
            }
    }
}
