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
    let networkId: String?
    let searchText: String?
    let limit: Int?
    let offset: Int?
    
    init(
        contractAddress: String? = nil,
        networkId: String? = nil,
        searchText: String? = nil,
        limit: Int? = nil,
        offset: Int? = nil
    ) {
        self.contractAddress = contractAddress
        self.networkId = networkId
        self.searchText = searchText == "" ? nil : searchText
        self.limit = limit
        self.offset = offset
    }
}
