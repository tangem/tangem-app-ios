//
//  Checkout.swift
//  TangemShopify
//
//  Created by [REDACTED_AUTHOR]
//

import MobileBuySDK

struct Checkout {
    let id: GraphQL.ID
    let webUrl: URL
    let lineItemsTotal: Decimal
    let total: Decimal
    let currencyCode: String
    let lineItems: [CheckoutLineItem]
    let address: Address?
    let shippingRate: ShippingRate?
    let availableShippingRates: [ShippingRate]
    let discount: Discount?
    let order: Order?

    init(_ checkout: Storefront.Checkout) {
        id = checkout.id
        webUrl = checkout.webUrl
        lineItemsTotal = checkout.lineItemsSubtotalPrice.amount
        total = checkout.totalPriceV2.amount
        currencyCode = checkout.currencyCode.rawValue
        lineItems = checkout.lineItems.edges.map { .init($0.node) }

        if let shippingAddress = checkout.shippingAddress {
            address = Address(shippingAddress)
        } else {
            address = nil
        }

        if let shippingLine = checkout.shippingLine {
            shippingRate = ShippingRate(shippingLine)
        } else {
            shippingRate = nil
        }

        availableShippingRates = checkout.availableShippingRates?.shippingRates?.map { ShippingRate($0) } ?? []

        if let discount = checkout.discountApplications.edges.first.map({ Discount($0.node) }) {
            self.discount = discount
        } else {
            discount = nil
        }

        if let order = checkout.order {
            self.order = Order(order)
        } else {
            order = nil
        }
    }
}

extension Checkout {
    var payCurrency: PayCurrency {
        PayCurrency(currencyCode: "USD", countryCode: "US")
    }

    var payCheckout: PayCheckout {
        let lineItems: [PayLineItem] = lineItems.map {
            PayLineItem(price: $0.amount, quantity: Int($0.quantity))
        }

        let shippingAddress = address?.payAddress
        let discount = discount?.payDiscount(itemsTotal: lineItemsTotal)

        let payCheckout = PayCheckout(
            id: id.rawValue,
            lineItems: lineItems,
            giftCards: [],
            discount: discount,
            shippingDiscount: nil,
            shippingAddress: shippingAddress,
            shippingRate: shippingRate?.payShippingRate,
            currencyCode: payCurrency.currencyCode,
            totalDuties: nil,
            subtotalPrice: total,
            needsShipping: true,
            totalTax: 0,
            paymentDue: total
        )

        return payCheckout
    }
}

extension Storefront.CheckoutQuery {
    @discardableResult
    func checkoutFieldsFragment() -> Storefront.CheckoutQuery {
        id()
            .ready()
            .webUrl()
            .currencyCode()
            .lineItemsSubtotalPrice { $0
                .amount()
            }
            .totalPriceV2 { $0
                .amount()
            }
            .lineItems(first: 250) { $0
                .edges { $0
                    .node { $0
                        .lineItemFieldsFragment()
                    }
                }
            }
            .shippingLine { $0
                .shippingRateFragment()
            }
            .availableShippingRates { $0
                .ready()
                .shippingRates { $0
                    .shippingRateFragment()
                }
            }
            .shippingAddress { $0
                .addressFieldsFragment()
            }
            .discountApplications(first: 250) { $0
                .edges { $0
                    .node { $0
                        .onDiscountCodeApplication { $0
                            .discountFieldsFragment()
                        }
                    }
                }
            }
            .order { $0
                .orderFieldsFragment()
            }
    }
}
