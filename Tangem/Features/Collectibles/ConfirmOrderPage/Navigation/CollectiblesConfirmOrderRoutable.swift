//
//  CollectiblesConfirmOrderRoutable.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

@MainActor
protocol CollectiblesConfirmOrderRoutable: AnyObject {
    func openPackReveal(wonCard: CollectiblesWonCard, assets: CollectiblesRevealAssets)
    func returnToMachine()
    func closePackFlow()
}
