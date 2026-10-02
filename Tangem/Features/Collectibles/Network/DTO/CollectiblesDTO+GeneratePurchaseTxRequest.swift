//
//  CollectiblesDTO+GeneratePurchaseTxRequest.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

extension CollectiblesDTO {
    struct GeneratePurchaseTxRequest: Encodable {
        let fromAddress: String
        let machineID: String
        let toAddress: String

        private enum CodingKeys: String, CodingKey {
            case fromAddress
            case machineID = "machineId"
            case toAddress
        }
    }
}
