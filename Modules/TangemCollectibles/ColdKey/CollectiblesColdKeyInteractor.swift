//
//  CollectiblesColdKeyInteractor.swift
//  TangemCollectibles
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

public import Foundation
public import BlockchainSdk

/// Every ceremony the vault's cold owner key takes part in. Both derive the key and persist the result, so
/// they belong to one object — split across two, they would answer "which key" separately and drift apart.
public protocol CollectiblesColdKeyInteractor {
    /// Persists what it derives, so the tap it costs is paid once per wallet.
    func derive() async throws

    /// - Parameter coldKey: the key `message` was compiled around. A signature from any other key would be
    ///   broadcast and rejected, so implementations check rather than assume.
    func sign(message: Data, coldKey: Wallet.PublicKey) async throws -> Data
}

public protocol CollectiblesColdKeyInteractorProvider: AnyObject {
    var collectiblesColdKeyInteractor: CollectiblesColdKeyInteractor { get }
}

/// For a wallet that cannot reach its cold key at all: a locked one, a preview, or a model that has gone away.
public struct UnavailableCollectiblesColdKeyInteractor: CollectiblesColdKeyInteractor {
    public init() {}

    public func derive() async throws {
        throw "This wallet cannot derive the collectibles account's key"
    }

    public func sign(message: Data, coldKey: Wallet.PublicKey) async throws -> Data {
        throw "This wallet cannot sign for the collectibles account"
    }
}
