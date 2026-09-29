//
//  TonConnectConnectEventFactory.swift
//  TangemModules
//
//  Created by Dean Rie
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TonSwift

/// Produces the `ConnectEvent` the wallet sends after the user approved a connection.
///
/// Answers every requested item: `ton_addr` with the account data, `ton_proof` with a signature made
/// through `TonConnectSigner`, anything else with the per-item error 400 the spec mandates.
public struct TonConnectConnectEventFactory {
    public struct Approval {
        public let event: TonConnectConnectEvent
        public let account: TonConnectSession.Account
    }

    private let deviceInfo: TonConnectDeviceInfo
    private let now: () -> Date

    public init(deviceInfo: TonConnectDeviceInfo, now: @escaping () -> Date = Date.init) {
        self.deviceInfo = deviceInfo
        self.now = now
    }

    /// - Parameters:
    ///   - publicKey: the account's Ed25519 public key (wallet v4R2 is derived from it).
    ///   - appDomain: validated host of the manifest `url`.
    ///   - eventID: value from `TonConnectSession.allocateEventID()` (0 for the connect event of a new session).
    public func makeApproval(
        request: TonConnectConnectRequest,
        publicKey: Data,
        network: TonConnectNetworkID,
        appDomain: String,
        eventID: Int,
        signer: any TonConnectSigner
    ) async throws -> Approval {
        let transferBuilder = try TonConnectTransferBuilder(publicKey: publicKey)
        let address = transferBuilder.address

        let account = TonConnectSession.Account(
            address: address.toRaw(),
            network: network,
            publicKey: publicKey.tonConnectHexString
        )

        var replies: [TonConnectConnectItemReply] = []
        replies.reserveCapacity(request.items.count)

        for item in request.items {
            switch item {
            case .tonAddress(let requestedNetwork):
                // The dApp may pin the network it wants; connecting a mainnet account to a testnet dApp
                // (or vice versa) must be refused, not silently answered with the wallet's network.
                if let requestedNetwork, requestedNetwork != network {
                    throw TonConnectError.badRequest("requested network \(requestedNetwork) does not match the wallet network \(network)")
                }
                replies.append(.tonAddress(TonConnectAddressItemReply(
                    address: account.address,
                    network: network,
                    publicKey: account.publicKey,
                    walletStateInit: try transferBuilder.stateInitBoc()
                )))

            case .tonProof(let payload):
                let proof = try await TonConnectProofMessage.makeProof(
                    address: address,
                    appDomain: appDomain,
                    payload: payload,
                    timestamp: UInt64(now().timeIntervalSince1970),
                    signer: signer
                )
                replies.append(.tonProof(proof))

            case .unsupported(let name):
                replies.append(.error(name: name, code: .methodNotSupported, message: "Unsupported connect item"))
            }
        }

        return Approval(
            event: .connect(id: eventID, items: replies, device: deviceInfo),
            account: account
        )
    }

    /// The `connect_error` event for a declined or failed connection.
    public func makeRejection(eventID: Int, error: TonConnectError) -> TonConnectConnectEvent {
        .connectError(id: eventID, code: error.protocolCode, message: error.protocolMessage)
    }
}
