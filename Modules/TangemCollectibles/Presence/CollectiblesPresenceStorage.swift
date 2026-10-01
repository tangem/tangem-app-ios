//
//  CollectiblesPresenceStorage.swift
//  TangemCollectibles
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

public protocol CollectiblesPresenceStorage: AnyObject {
    var collectiblesHasAccount: [String: Bool] { get set }
}
