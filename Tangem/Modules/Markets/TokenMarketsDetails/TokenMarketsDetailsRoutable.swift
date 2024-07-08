//
//  TokenMarketsDetailsRoutable.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

protocol TokenMarketsDetailsRoutable: AnyObject {
    func openTokenSelector(dataSource: MarketsDataSource, coinId: String, tokenItems: [TokenItem])
}
