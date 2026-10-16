//
//  CollectiblesMainRoutable.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

@MainActor
protocol CollectiblesMainRoutable: CollectiblesActionsMenuRoutable, CollectiblesAccountRoutable {
    func openMachine(for pack: CollectiblesPack)
}
