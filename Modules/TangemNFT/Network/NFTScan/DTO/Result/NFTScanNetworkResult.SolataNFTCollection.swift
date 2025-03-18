//
//  NFTScanNetwrkResult.SolataNFTCollection.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

extension NFTScanNetworkResult {
    struct SolanaNFTCollection: Decodable {
        let collection: String?
        let logoUrl: String?
        let ownsTotal: Int
        let itemsTotal: Int
        let description: String?
        let assets: [Asset]
    }
}
