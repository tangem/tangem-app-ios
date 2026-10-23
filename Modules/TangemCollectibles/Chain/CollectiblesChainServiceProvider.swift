//
//  CollectiblesChainServiceProvider.swift
//  TangemCollectibles
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

/// Hands over the chain service the vault is read and written through. Kept behind a protocol so the
/// module never resolves endpoints itself — that is the app's business.
public protocol CollectiblesChainServiceProvider {
    func service() throws -> any CollectiblesChainService
}
