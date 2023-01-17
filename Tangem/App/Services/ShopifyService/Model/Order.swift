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
        id = order.id
        number = Int(order.orderNumber)
        processedDate = order.processedAt
        fulfillmentStatus = order.fulfillmentStatus.rawValue
        financialStatus = order.financialStatus?.rawValue ?? ""
        statusUrl = order.statusUrl
        address = (order.shippingAddress?.formatted ?? []).joined(separator: ", ")
        if let discount = order.discountApplications.edges.first.map({ Discount($0.node) }) {
            self.discount = discount
        } else {
            discount = nil
        }
        total = order.totalPriceV2.amount
        currencyCode = order.totalPriceV2.currencyCode.rawValue
        lineItems = order.lineItems.edges.map { .init($0.node) }
    }
}

extension Storefront.OrderQuery {
    @discardableResult
    func orderFieldsFragment() -> Storefront.OrderQuery {
        cancelReason()
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
