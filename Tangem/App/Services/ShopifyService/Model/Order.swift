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
