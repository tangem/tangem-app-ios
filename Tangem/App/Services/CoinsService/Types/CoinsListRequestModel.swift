//
//  CoinsRequestModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation

struct CoinsListRequestModel: Encodable {
    let contractAddress: String?
    let networkIds: [String]
    let searchText: String?
    let limit: Int?
    let offset: Int?
    
    init(
        contractAddress: String? = nil,
        networkIds: [String] = [],
        searchText: String? = nil,
        limit: Int? = nil,
        offset: Int? = nil
    ) {
        self.contractAddress = contractAddress
        self.networkIds = networkIds
        self.searchText = searchText == "" ? nil : searchText
        self.limit = limit
        self.offset = offset
    }
}
