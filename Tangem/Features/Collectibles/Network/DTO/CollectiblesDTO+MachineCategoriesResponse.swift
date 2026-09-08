//
//  CollectiblesDTO+MachineCategoriesResponse.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

extension CollectiblesDTO {
    /// Response for GET api/v1/machine/categories.
    struct MachineCategoriesResponse: Decodable {
        let categories: [MachineCategory]
        let totalMachinesQuantity: Int
    }
}
