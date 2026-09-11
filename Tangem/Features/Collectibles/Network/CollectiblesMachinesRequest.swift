//
//  CollectiblesMachinesRequest.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

struct CollectiblesMachinesRequest {
    let categoryID: String?
    let search: String?
    let limit: Int?
    let cursor: String?

    init(categoryID: String? = nil, search: String? = nil, limit: Int? = nil, cursor: String? = nil) {
        self.categoryID = categoryID
        self.search = search
        self.limit = limit
        self.cursor = cursor
    }
}
