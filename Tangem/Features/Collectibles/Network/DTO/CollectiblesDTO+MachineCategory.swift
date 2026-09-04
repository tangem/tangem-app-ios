//
//  CollectiblesDTO+MachineCategory.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

extension CollectiblesDTO {
    struct MachineCategory: Decodable {
        let id: String
        let name: String
        let machinesQuantity: Int
    }
}
