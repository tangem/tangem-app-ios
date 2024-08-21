//
//  MarketsTokenDetailsLinks.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

struct MarketsTokenDetailsLinks: Codable {
    let officialLinks: [LinkInfo]
    let social: [LinkInfo]
    let repository: [LinkInfo]
    let blockchainSite: [LinkInfo]
}

extension MarketsTokenDetailsLinks {
    struct LinkInfo: Codable {
        let id: String?
        let title: String
        let link: String
    }
}
