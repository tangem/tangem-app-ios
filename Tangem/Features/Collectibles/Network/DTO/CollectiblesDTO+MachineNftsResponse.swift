//
//  CollectiblesDTO+MachineNftsResponse.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

extension CollectiblesDTO {
    struct MachineNftsResponse: Decodable {
        let nfts: [MachineNft]
        let hasMore: Bool
    }
}
