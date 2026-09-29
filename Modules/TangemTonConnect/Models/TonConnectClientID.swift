//
//  TonConnectClientID.swift
//  TangemModules
//
//  Created by Dean Rie
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

/// A TON Connect `client_id`: the 32-byte X25519 public key of one side of a session.
///
/// On the bridge and in deep links the id travels as 64 lowercase hex characters.
public struct TonConnectClientID: Hashable, Codable, Sendable, CustomStringConvertible {
    public static let byteCount = 32

    public let publicKey: Data

    public init(publicKey: Data) throws {
        guard publicKey.count == Self.byteCount else {
            throw TonConnectError.invalidClientID
        }
        self.publicKey = publicKey
    }

    /// Parses the 64-character hex form used in `tc://` links and bridge envelopes.
    public init(hexString: String) throws {
        guard hexString.count == Self.byteCount * 2, let data = Data(tonConnectHex: hexString) else {
            throw TonConnectError.invalidClientID
        }
        try self.init(publicKey: data)
    }

    public var hexString: String { publicKey.tonConnectHexString }

    public var description: String { hexString }
}
