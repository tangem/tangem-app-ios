//
//  Order.swift
//  TangemShopify
//
//  Created by [REDACTED_AUTHOR]
//

import MobileBuySDK

struct Order {
    let id: GraphQL.ID
    let number: Int
    let processedDate: Date
    let fulfillmentStatus: String
    let financialStatus: String
    let statusUrl: URL
    let address: String
    let discount: Discount?
    let total: Decimal
    let currencyCode: String
    let lineItems: [CheckoutLineItem]
}

extension Order {
    init(_ order: Storefront.Order) {
        self.id = order.id
        self.number = Int(order.orderNumber)
        self.processedDate = order.processedAt
        self.fulfillmentStatus = order.fulfillmentStatus.rawValue
        self.financialStatus = order.financialStatus?.rawValue ?? ""
        self.statusUrl = order.statusUrl
        self.address = (order.shippingAddress?.formatted ?? []).joined(separator: ", ")
        if let discount = order.discountApplications.edges.first.map({ Discount($0.node) }) {
            self.discount = discount
        } else {
            self.discount = nil
        }
        self.total = order.totalPriceV2.amount
        self.currencyCode = order.totalPriceV2.currencyCode.rawValue
        self.lineItems = order.lineItems.edges.map { .init($0.node) }
    }
}

extension Storefront.OrderQuery {
    @discardableResult
    func orderFieldsFragment() -> Storefront.OrderQuery {
        self
            .cancelReason()
            .canceledAt()
            .currencyCode()
            .customerLocale()
            .customerUrl()
            .edited()
            .email()
            .financialStatus()
            .fulfillmentStatus()
            .id()
            .name()
            .discountApplications(first: 250) { $0
                .edges { $0
                    .node { $0
                        .onDiscountCodeApplication { $0
                            .discountFieldsFragment()
                        }
                    }
                }
            }
            .totalPriceV2 { $0
                .currencyCode()
                .amount()
            }
            .lineItems(first: 250) { $0
                .edges { $0
                    .node { $0
                        .lineItemFieldsFragment()
                    }
                }
            }
            .orderNumber()
            .phone()
            .processedAt()
            .shippingAddress { $0
                .address1()
                .address2()
                .city()
                .company()
                .country()
                .countryCodeV2()
                .firstName()
                .formatted()
                .formattedArea()
                .id()
                .lastName()
                .latitude()
                .longitude()
                .name()
                .phone()
                .province()
                .provinceCode()
                .zip()
            }
            .statusUrl()
    }
}
