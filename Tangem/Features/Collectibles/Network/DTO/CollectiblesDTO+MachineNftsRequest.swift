//
//  CollectiblesDTO+MachineNftsRequest.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

extension CollectiblesDTO {
    struct MachineNftsRequest: Encodable {
        let page, limit: Int
    }
}
