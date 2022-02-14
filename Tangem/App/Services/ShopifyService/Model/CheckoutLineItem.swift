//
//  CheckoutLineItem.swift
//  TangemShopify
//
//  Created by [REDACTED_AUTHOR]
//

import MobileBuySDK
import Foundation

struct CheckoutLineItem {
    let id: GraphQL.ID
    let title: String
    let quantity: Int32
    let amount: Decimal
    
    static func checkoutInput(variantID: GraphQL.ID, quantity: Int32) -> CheckoutLineItem {
        return CheckoutLineItem(id: variantID, title: "", quantity: quantity, amount: 0)
    }
}

extension CheckoutLineItem {
    init(_ item: Storefront.CheckoutLineItem) {
        self.id = item.id
        self.title = item.title
        self.quantity = item.quantity
        self.amount = item.variant?.priceV2.amount ?? Decimal()
    }
}

extension Storefront.CheckoutLineItemQuery {
    @discardableResult
    func lineItemFieldsFragment() -> Storefront.CheckoutLineItemQuery {
        self
            .id()
            .title()
            .quantity()
            .variant() { $0
                .priceV2() { $0
                    .amount()
                }
            }
    }
}
