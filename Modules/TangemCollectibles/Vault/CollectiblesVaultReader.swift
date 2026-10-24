//
//  CollectiblesVaultReader.swift
//  TangemCollectibles
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

public import Foundation

/// Chain read of the vault account. `nil` means "no vault" — a data-less system-owned account at the PDA
/// (a stray transfer) counts, since `init_vault` handles it and only the program can allocate data there.
/// A throw means "unreachable or unparseable" and must never downgrade a previously known state.
public protocol CollectiblesVaultReader: AnyObject {
    func vaultInfo(coldOwner: Data) async throws -> CollectiblesVaultInfo?
}
