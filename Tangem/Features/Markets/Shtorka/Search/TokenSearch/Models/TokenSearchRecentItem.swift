//
//  TokenSearchRecentItem.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

enum TokenSearchRecentItem: Codable, Hashable {
    case query(String)
    case marketAsset(MarketsTokenModel)
}
