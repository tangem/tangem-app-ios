//
//  NFTScanNetworkResult.Attribute.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

extension NFTScanNetworkResult.Asset {
    struct Attribute: Decodable {
        let attributeName: String
        let attributeValue: String
        let percentage: String?
    }
}
