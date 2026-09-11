//
//  CollectiblesDTO+MachinesResponse.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

extension CollectiblesDTO {
    /// Response for GET api/v1/machine/machines.
    struct MachinesResponse: Decodable {
        let machines: [Machine]
        let hasNext: Bool
        let cursor: String?
    }
}
