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
    
    init(_ item: Storefront.CheckoutLineItem) {
        self.id = item.id
        self.title = item.title
        self.quantity = item.quantity
        self.amount = item.variant?.priceV2.amount ?? Decimal()
    }

    init(variantID: GraphQL.ID, title: String, quantity: Int32, amount: Decimal) {
        self.id = variantID
        self.title = title
        self.quantity = quantity
        self.amount = amount
    }
    
    static func checkoutInput(variantID: GraphQL.ID, quantity: Int32) -> CheckoutLineItem {
        return CheckoutLineItem(variantID: variantID, title: "", quantity: quantity, amount: 0)
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
