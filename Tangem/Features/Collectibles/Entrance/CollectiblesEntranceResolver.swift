//
//  CollectiblesEntranceResolver.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

enum CollectiblesEntranceResolver {
    @MainActor
    static func resolve(
        for accountModel: (any CollectiblesAccountModel)?,
        isRegionRestricted: Bool
    ) async -> Outcome {
        if accountModel?.hasAccount != true, accountModel?.state == .unresolved {
            await accountModel?.refreshState()
        }

        switch (accountModel?.hasAccount ?? false, isRegionRestricted) {
        case (true, _): return .open(.main)
        case (false, true): return .regionRestricted
        case (false, false): return .open(.welcome)
        }
    }
}

// MARK: - Outcome

extension CollectiblesEntranceResolver {
    enum Outcome: Equatable {
        case open(CollectiblesCoordinator.Options.Destination)
        case regionRestricted
    }
}
