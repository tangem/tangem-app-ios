//
//  PolymarketMainRefreshCenter.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

final class PolymarketMainRefreshCenter {
    typealias Handler = @MainActor (Scope) async -> Void

    private var handlers: [Handler] = []

    func register(_ handler: @escaping Handler) {
        handlers.append(handler)
    }

    @MainActor
    func refresh(_ scope: Scope) async {
        let handlers = handlers

        await withTaskGroup(of: Void.self) { group in
            for handler in handlers {
                group.addTask { await handler(scope) }
            }
        }
    }
}

// MARK: - Scope

extension PolymarketMainRefreshCenter {
    enum Scope {
        case full
        case balance
        case accountFunds
    }
}
