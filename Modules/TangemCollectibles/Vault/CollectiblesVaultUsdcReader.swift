//
//  CollectiblesVaultUsdcReader.swift
//  TangemCollectibles
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

public import Foundation

/// Chain read of the vault's USDC balance in base units. A token account that does not exist reads as a `nil` account.
public protocol CollectiblesVaultUsdcReader: AnyObject {
    func usdcAccount(coldOwner: Data) async throws -> CollectiblesVaultUsdcInfo
}
