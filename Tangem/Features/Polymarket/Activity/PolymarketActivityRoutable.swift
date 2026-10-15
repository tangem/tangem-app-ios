//
//  PolymarketActivityRoutable.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemPolymarket

protocol PolymarketActivityRoutable: AnyObject {
    func closeActivity()

    func shareActivityExport(url: URL)

    @MainActor
    func openActivityDetails(record: PolymarketActivityRecord)
}
