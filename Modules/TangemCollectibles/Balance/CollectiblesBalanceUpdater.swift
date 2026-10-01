//
//  CollectiblesBalanceUpdater.swift
//  TangemCollectibles
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

/// The write side of the balance: the manager reports what it read off the chain and nothing more.
/// How that turns into a displayable balance is the app's business.
public protocol CollectiblesBalanceUpdater {
    func update(_ state: CollectiblesBalanceState)
}
