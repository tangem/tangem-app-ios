//
//  TangemTokenList.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation

struct TangemTokenList: Codable {
    let imageHost: URL?
    let tokens: [TangemTokenEntity]
}
