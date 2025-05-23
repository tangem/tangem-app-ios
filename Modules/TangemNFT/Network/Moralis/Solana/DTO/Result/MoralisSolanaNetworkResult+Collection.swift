//
//  MoralisSolanaNetworkResult+Collection.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

extension MoralisSolanaNetworkResult {
    struct Collection: Decodable {
        let collectionAddress: String?
        let name: String?
        let description: String?
        let imageOriginalUrl: String?
        let externalUrl: String?
        let metaplexUrl: String?
        let sellerFeeBasisPoints: Int?
    }
}
