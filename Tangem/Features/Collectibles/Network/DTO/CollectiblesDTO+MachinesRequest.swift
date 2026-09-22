//
//  CollectiblesDTO+MachinesRequest.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

extension CollectiblesDTO {
    /// Query for GET api/v1/machine/machines.
    struct MachinesRequest: Encodable {
        let categoryID, search, cursor: String?
        let limit: Int?

        init(categoryID: String? = nil, search: String? = nil, limit: Int? = nil, cursor: String? = nil) {
            self.categoryID = categoryID
            self.search = search
            self.limit = limit
            self.cursor = cursor
        }

        private enum CodingKeys: String, CodingKey {
            case categoryID = "categoryId"
            case search, limit, cursor
        }
    }
}
