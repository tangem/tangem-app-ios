//
//  UTXONetworkParams.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

protocol UTXONetworkParams {
    var p2pkhPrefix: UInt8 { get }
    var p2shPrefix: UInt8 { get }
    var bech32Prefix: String { get }
    var dustRelayTxFee: Int { get }
    var coinType: UInt32 { get }
    var signHashType: UTXONetworkParamsSignHashType { get }
    var publicKeyType: UTXONetworkParamsPublicKeyType { get }
}

enum UTXONetworkParamsSignHashType: Hashable {
    case bitcoinAll
    case bitcoinCashAll

    var value: UInt32 {
        switch self {
        case .bitcoinAll: 0x01
        case .bitcoinCashAll: 0x41
        }
    }
}

/// Have to be equal to `PublicKey` type which used for a address created
enum UTXONetworkParamsPublicKeyType: Hashable {
    case compressed
    case asIs
}
