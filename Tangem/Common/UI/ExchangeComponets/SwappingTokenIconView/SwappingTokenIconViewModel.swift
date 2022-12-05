//
//  SwappingTokenIconViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation

struct SwappingTokenIconViewModel: Identifiable, Hashable {
    var id: Int { hashValue }

    let imageURL: URL
    let networkURL: URL?
    let tokenSymbol: String

    init(
        imageURL: URL,
        networkURL: URL? = nil,
        tokenSymbol: String
    ) {
        self.imageURL = imageURL
        self.networkURL = networkURL
        self.tokenSymbol = tokenSymbol
    }
}
