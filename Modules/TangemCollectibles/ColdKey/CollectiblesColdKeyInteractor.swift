//
//  CollectiblesColdKeyInteractor.swift
//  TangemCollectibles
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

public import Foundation
public import BlockchainSdk

public protocol CollectiblesColdKeySigner {
    /// - Parameter coldKey: the key `message` was compiled around. A signature from any other key would be
    ///   broadcast and rejected, so implementations check rather than assume.
    func sign(message: Data, coldKey: Wallet.PublicKey) async throws -> Data
}

public protocol CollectiblesColdKeySessionWork {
    associatedtype Output

    func run(signer: any CollectiblesColdKeySigner) async throws -> Output
}

/// Every ceremony the vault's cold owner key takes part in. Deriving the key and signing with it belong to one
/// object, which hands the narrower `CollectiblesColdKeySigner` into the session it opens — implemented by two
/// objects, they would answer "which key" separately and drift apart.
public protocol CollectiblesColdKeyInteractor: CollectiblesColdKeySigner {
    func derive<Work: CollectiblesColdKeySessionWork>(andRun work: Work) async throws -> Work.Output
}

public protocol CollectiblesColdKeyInteractorProvider: AnyObject {
    var collectiblesColdKeyInteractor: CollectiblesColdKeyInteractor { get }
}

/// For a wallet that cannot reach its cold key at all: a locked one, a preview, or a model that has gone away.
public struct UnavailableCollectiblesColdKeyInteractor: CollectiblesColdKeyInteractor {
    public init() {}

    public func derive<Work: CollectiblesColdKeySessionWork>(andRun work: Work) async throws -> Work.Output {
        throw "This wallet cannot derive the collectibles account's key"
    }

    public func sign(message: Data, coldKey: Wallet.PublicKey) async throws -> Data {
        throw "This wallet cannot sign for the collectibles account"
    }
}
