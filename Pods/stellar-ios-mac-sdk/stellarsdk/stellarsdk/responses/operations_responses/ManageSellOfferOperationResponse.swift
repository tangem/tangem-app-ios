//
//  ManageSellOfferOperationResponse.swift
//  stellarsdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2019 Soneso. All rights reserved.
//

import Foundation

public class ManageSellOfferOperationResponse: ManageOfferOperationResponse {
    /**
     Initializer - creates a new instance by decoding from the given decoder.
     
     - Parameter decoder: The decoder containing the data
     */
    public required init(from decoder: Decoder) throws {
        try super.init(from: decoder)
    }
}
