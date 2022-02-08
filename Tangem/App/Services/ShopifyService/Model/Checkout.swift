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
        self.id = checkout.id
        self.webUrl = checkout.webUrl
        self.lineItemsTotal = checkout.lineItemsSubtotalPrice.amount
        self.total = checkout.totalPriceV2.amount
        self.currencyCode = checkout.currencyCode.rawValue
        self.lineItems = checkout.lineItems.edges.map { .init($0.node) }

        if let shippingAddress = checkout.shippingAddress {
            self.address = Address(shippingAddress)
        } else {
            self.address = nil
        }
        
        if let shippingLine = checkout.shippingLine {
            self.shippingRate = ShippingRate(shippingLine)
        } else {
            self.shippingRate = nil
        }
        
        self.availableShippingRates = checkout.availableShippingRates?.shippingRates?.map { ShippingRate($0) } ?? []
        
        if let discount = checkout.discountApplications.edges.first.map( { Discount($0.node) } ) {
            self.discount = discount
        } else {
            self.discount = nil
        }
        
        if let order = checkout.order {
            self.order = Order(order)
        } else {
            self.order = nil
        }
    }
}

extension Checkout {
    var payCurrency: PayCurrency {
        PayCurrency(currencyCode: "USD", countryCode: "US")
    }
    
    var payCheckout: PayCheckout {
        let lineItems: [PayLineItem] = self.lineItems.map {
            PayLineItem(price: $0.amount, quantity: Int($0.quantity))
        }
        
        let shippingAddress = address?.payAddress
        
        let discount = discount?.payDiscount(itemsTotal: lineItemsTotal)
        
        let total = self.total
        
        let payCheckout = PayCheckout(
            id: id.rawValue,
            lineItems: lineItems,
            giftCards: [],
            discount: discount,
            shippingDiscount: nil,
            shippingAddress: shippingAddress,
            shippingRate: shippingRate?.payShippingRate,
            currencyCode: self.payCurrency.currencyCode,
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
        self
            .id()
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
