//
//  PolymarketActivityRoutable.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

protocol PolymarketActivityRoutable: AnyObject {
    func closeActivity()

    func shareActivityExport(url: URL)
}
