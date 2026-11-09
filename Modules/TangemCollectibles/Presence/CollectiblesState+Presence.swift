//
//  CollectiblesState+Presence.swift
//  TangemCollectibles
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

public extension CollectiblesState {
    enum PresenceRecord {
        case exists
        case absent
        case unchanged
    }

    func hasAccount(isRecorded: Bool) -> Bool {
        switch self {
        case .ready, .rekeyRequired: true
        case .notOnboarded: false
        case .unresolved, .coldOwnerNotDerived: isRecorded
        }
    }

    func isRelinkRequired(isRecorded: Bool) -> Bool {
        switch self {
        case .rekeyRequired: true
        case .coldOwnerNotDerived: isRecorded
        case .unresolved, .notOnboarded, .ready: false
        }
    }

    func isSyncRequired(isRecorded: Bool) -> Bool {
        switch self {
        case .coldOwnerNotDerived: isRecorded
        case .unresolved, .notOnboarded, .rekeyRequired, .ready: false
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
