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
        let turboMode: TurboMode?

        private enum CodingKeys: String, CodingKey {
            case fromAddress
            case machineID = "machineId"
            case toAddress
            case turboMode
        }
    }

    struct TurboMode: Encodable {
        let enabled: Bool
        let buybackAddress: String?
    }
}
