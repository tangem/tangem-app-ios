//
//  TonConnectDeepLink.swift
//  TangemModules
//
//  Created by Dean Rie
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

/// A parsed TON Connect link (`spec/deeplinks.md`): unified `tc://`, the wallet's universal link or a
/// wallet-specific custom scheme all carry the same query parameters.
public struct TonConnectDeepLink: Equatable, Sendable {
    /// Where to send the user after the request is approved or declined.
    public enum ReturnStrategy: Equatable, Sendable {
        /// Return to the app that opened the link (default).
        case back
        /// Stay in the wallet.
        case none
        /// Open the given URL.
        case url(URL)
    }

    public let protocolVersion: Int
    /// The dApp's session public key.
    public let dAppClientID: TonConnectClientID
    /// `nil` for the "empty" form `?id=…&ret=…` that only carries a return target.
    public let connectRequest: TonConnectConnectRequest?
    public let returnStrategy: ReturnStrategy
    /// Analytics correlation id; reuse it when posting the connect event.
    public let traceID: String?

    public init(
        protocolVersion: Int,
        dAppClientID: TonConnectClientID,
        connectRequest: TonConnectConnectRequest?,
        returnStrategy: ReturnStrategy,
        traceID: String?
    ) {
        self.protocolVersion = protocolVersion
        self.dAppClientID = dAppClientID
        self.connectRequest = connectRequest
        self.returnStrategy = returnStrategy
        self.traceID = traceID
    }
}
