//
//  CollectiblesDTO+GenerateBuybackDataRequest.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

extension CollectiblesDTO {
    struct GenerateBuybackDataRequest: Encodable {
        let fromAddress: String
        let nftAddress: String
        let toAddress: String
    }
}
