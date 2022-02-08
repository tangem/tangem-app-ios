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
    
    init(id: GraphQL.ID, number: Int, processedDate: Date, fulfillmentStatus: String, financialStatus: String, statusUrl: URL, address: String) {
        self.id = id
        self.number = number
        self.processedDate = processedDate
        self.fulfillmentStatus = fulfillmentStatus
        self.financialStatus = financialStatus
        self.statusUrl = statusUrl
        self.address = address
    }

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

#warning("TODO")
extension Storefront.OrderQuery {
    @discardableResult
    func orderFieldsFragment() -> Storefront.OrderQuery {
        self
        // TODO
            .cancelReason()
            .canceledAt()
            .currencyCode()
//            .currentSubtotalPrice()
//            .currentTotalDuties()
//            .currentTotalPrice()
//            .currentTotalTax()
            .customerLocale()
            .customerUrl()
//            .discountApplications()
            .edited()
            .email()
            .financialStatus()
            .fulfillmentStatus()
            .id()
//            .lineItems()
//            .metafield()
//            .metafields()
            .name()
            .orderNumber()
//            .originalTotalDuties()
//            .originalTotalPrice()
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
//            .shippingDiscountAllocations()
            .statusUrl()
//            .subtotalPriceV2()
//            .successfulFulfillments()
//            .totalPriceV2()
//            .totalRefundedV2()
//            .totalShippingPriceV2()
//            .totalTaxV2()
    }
}
