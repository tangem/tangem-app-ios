//
//  SendAddressParserService.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import BlockchainSdk

struct SendAddressParserService {
    let blockchain: Blockchain

    func parse(address: String, additionalField: String) -> (address: String, additionalField: String?) {
        guard
            case .xrp = blockchain,
            let xrpAddress = try? XRPAddress(xAddress: address)
        else {
            return (address, additionalField)
        }

        let tagString: String?
        if let tag = xrpAddress.tag {
            tagString = "\(tag)"
        } else {
            tagString = nil
        }
        return (xrpAddress.rAddress, tagString)
    }
}
