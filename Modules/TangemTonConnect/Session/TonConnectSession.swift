//
//  TonConnectSession.swift
//  TangemModules
//
//  Created by Dean Rie
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import BigInt
import Foundation

/// Persistent record of one approved dApp connection.
///
/// Holds everything except the wallet's session *secret* key, which the app keeps in the Keychain under
/// `id` and hands to `TonConnectSessionCrypto` when a message needs to be opened or sealed.
public struct TonConnectSession: Codable, Equatable, Sendable, Identifiable {
    /// The account exposed to the dApp; fixed for the lifetime of the session.
    public struct Account: Codable, Equatable, Sendable {
        /// Raw form `0:<hex>`.
        public let address: String
        public let network: TonConnectNetworkID
        /// Hex without `0x`.
        public let publicKey: String

        public init(address: String, network: TonConnectNetworkID, publicKey: String) {
            self.address = address
            self.network = network
            self.publicKey = publicKey
        }
    }

    public let id: UUID
    public let dAppClientID: TonConnectClientID
    /// The wallet's session public key — what the dApp encrypts to.
    public let walletClientID: TonConnectClientID
    public let bridgeURL: URL
    public let manifest: TonConnectManifest
    /// Host of `manifest.url`, bound into every `ton_proof` / `signData` signature.
    public let appDomain: String
    public let account: Account
    public let createdAt: Date

    /// Last processed `AppRequest.id`; subsequent ids must be strictly greater.
    public private(set) var lastRequestID: String?
    /// Counter for wallet-emitted events (`connect`, `disconnect`).
    public private(set) var nextEventID: Int
    /// Last SSE event id seen on the bridge, for `last_event_id` on reconnect.
    public var lastBridgeEventID: String?

    public init(
        id: UUID = UUID(),
        dAppClientID: TonConnectClientID,
        walletClientID: TonConnectClientID,
        bridgeURL: URL,
        manifest: TonConnectManifest,
        appDomain: String,
        account: Account,
        createdAt: Date = Date(),
        nextEventID: Int = 0
    ) {
        self.id = id
        self.dAppClientID = dAppClientID
        self.walletClientID = walletClientID
        self.bridgeURL = bridgeURL
        self.manifest = manifest
        self.appDomain = appDomain
        self.account = account
        self.createdAt = createdAt
        self.nextEventID = nextEventID
    }

    /// Enforces the per-session monotonic request id rule (`spec/rpc.md` § AppRequest).
    ///
    /// The first id is accepted as the baseline; every later id must be strictly greater. Ids are
    /// compared as unsigned integers — the reference SDK uses millisecond timestamps.
    /// Longest request id accepted (the reference SDK sends 13-digit millisecond timestamps).
    public static let maxRequestIDLength = 64

    public mutating func acceptRequest(id: String) throws {
        guard !id.isEmpty, id.count <= Self.maxRequestIDLength,
              id.utf8.allSatisfy({ (UInt8(ascii: "0") ... UInt8(ascii: "9")).contains($0) }),
              let incoming = BigUInt(id, radix: 10) else {
            throw TonConnectError.badRequest("request id must be a non-negative integer")
        }

        if let lastRequestID, let last = BigUInt(lastRequestID, radix: 10), incoming <= last {
            throw TonConnectError.requestIDNotIncreasing(received: id, last: lastRequestID)
        }

        lastRequestID = id
    }

    /// Allocates the id for the next wallet event.
    public mutating func allocateEventID() -> Int {
        defer { nextEventID += 1 }
        return nextEventID
    }
}
