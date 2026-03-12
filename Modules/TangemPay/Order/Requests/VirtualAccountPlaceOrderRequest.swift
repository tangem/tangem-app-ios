//
//  VirtualAccountPlaceOrderRequest.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

public struct VirtualAccountPlaceOrderRequest: Encodable {
    let type: String
    let productionSpecificationName: String
    let customerId: String
    let linkAddress: String
    let linkNetwork: String
    let linkAddressMessage: String
    let linkAddressSignature: String

    public init(
        type: String,
        productionSpecificationName: String,
        customerId: String,
        linkAddress: String,
        linkNetwork: String,
        linkAddressMessage: String,
        linkAddressSignature: String
    ) {
        self.type = type
        self.productionSpecificationName = productionSpecificationName
        self.customerId = customerId
        self.linkAddress = linkAddress
        self.linkNetwork = linkNetwork
        self.linkAddressMessage = linkAddressMessage
        self.linkAddressSignature = linkAddressSignature
    }
}
