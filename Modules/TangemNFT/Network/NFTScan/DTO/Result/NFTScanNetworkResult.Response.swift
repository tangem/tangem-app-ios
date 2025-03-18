//
//  NFTScanNetworkResult.SolanaNFTCollections.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

extension NFTScanNetworkResult {
    struct Response<T: Decodable>: Decodable {
        let code: Int
        let msg: String?
        let data: T
    }
}
