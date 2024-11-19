//
//  MarketsRoutable.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

protocol MarketsRoutable: AnyObject {
    func openFilterOrderBottonSheet(with provider: MarketsListDataFilterProvider)
    func openMarketsTokenDetails(for tokenInfo: MarketsTokenModel)
}
