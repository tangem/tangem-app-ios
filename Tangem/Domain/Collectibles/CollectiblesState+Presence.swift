//
//  CollectiblesState+Presence.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import TangemCollectibles

extension CollectiblesState {
    enum PresenceRecord {
        case exists
        case absent
        case unchanged
    }

    func hasAccount(markedLocally: Bool) -> Bool {
        switch self {
        case .ready, .rekeyRequired: true
        case .notOnboarded, .coldOwnerNotDerived: false
        case .unresolved: markedLocally
        }
    }

    var presenceRecord: PresenceRecord {
        switch self {
        case .ready, .rekeyRequired: .exists
        case .notOnboarded: .absent
        case .unresolved, .coldOwnerNotDerived: .unchanged
        }
    }
}
