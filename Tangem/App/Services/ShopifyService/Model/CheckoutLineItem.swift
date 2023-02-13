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
    let sku: String
    let quantity: Int32
    let amount: Decimal

    static func checkoutInput(variantID: GraphQL.ID, quantity: Int32) -> CheckoutLineItem {
        return CheckoutLineItem(id: variantID, title: "", sku: "", quantity: quantity, amount: 0)
    }
}

extension CheckoutLineItem {
    init(_ item: Storefront.CheckoutLineItem) {
        id = item.id
        title = item.title
        sku = item.variant?.sku ?? ""
        quantity = item.quantity
        amount = item.variant?.priceV2.amount ?? Decimal()
    }

    init(_ item: Storefront.OrderLineItem) {
        id = GraphQL.ID(rawValue: "")
        title = item.title
        sku = item.variant?.sku ?? ""
        quantity = item.quantity
        amount = item.variant?.priceV2.amount ?? Decimal()
    }
}

extension Storefront.CheckoutLineItemQuery {
    @discardableResult
    func lineItemFieldsFragment() -> Storefront.CheckoutLineItemQuery {
        id()
            .title()
            .quantity()
            .variant { $0
                .sku()
                .priceV2 { $0
                    .amount()
                }
            }
    }
}

extension Storefront.OrderLineItemQuery {
    @discardableResult
    func lineItemFieldsFragment() -> Storefront.OrderLineItemQuery {
        title()
            .quantity()
            .variant { $0
                .sku()
                .priceV2 { $0
                    .amount()
                }
            }
    }
}
