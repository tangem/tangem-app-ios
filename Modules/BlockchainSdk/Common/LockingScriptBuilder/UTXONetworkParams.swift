//
//  UTXONetworkParams.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

protocol UTXONetworkParams {
    var p2pkhPrefix: UInt8 { get }
    var p2shPrefix: UInt8 { get }
    var bech32Prefix: String { get }
    var signHashType: UTXONetworkParamsSignHashType { get }
    var dustCalculator: UTXONetworkParamsDustCalculator { get }
}

enum UTXONetworkParamsSignHashType: Hashable {
    case bitcoinAll
    case bitcoinCashAll

    var value: UInt8 {
        switch self {
        case .bitcoinAll: 0x01
        case .bitcoinCashAll: 0x41
        }
    }
}
