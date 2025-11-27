//
//  TopMarketWidgetRoutable.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

protocol TopMarketWidgetRoutable: AnyObject {
    func openMarketsTokenDetails(for tokenInfo: MarketsTokenModel)
}
