//
//  PolkadotNetwork.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk

enum PolkadotNetwork {
    /// Polkadot blockchain for isTestnet = false
    case polkadot(curve: EllipticCurve)
    /// Polkadot blockchain for isTestnet = true
    case westend(curve: EllipticCurve)
    /// Kusama blockchain
    case kusama(curve: EllipticCurve)
    /// Azero blockchain
    case azero(curve: EllipticCurve, testnet: Bool)
    /// Joystream blockchain
    case joystream(curve: EllipticCurve)
    /// Bittensor blockchain
    case bittensor(curve: EllipticCurve)
    /// Energy Web X blockchain
    case energyWebX(curve: EllipticCurve)

    init?(blockchain: Blockchain) {
        switch blockchain {
        case .polkadot(let curve, let isTestnet):
            self = isTestnet ? .westend(curve: curve) : .polkadot(curve: curve)
        case .kusama(let curve):
            self = .kusama(curve: curve)
        case .azero(let curve, let isTestnet):
            self = .azero(curve: curve, testnet: isTestnet)
        case .joystream(let curve):
            self = .joystream(curve: curve)
        case .bittensor(let curve):
            self = .bittensor(curve: curve)
        case .energyWebX(let curve):
            self = .energyWebX(curve: curve)
        default:
            return nil
        }
    }

    /// https://wiki.polkadot.network/docs/build-protocol-info#addresses
    var addressPrefix: UInt {
        switch self {
        case .polkadot:
            return 0
        case .kusama:
            return 2
        case .westend, .azero, .bittensor, .energyWebX:
            return 42
        case .joystream:
            return 126
        }
    }

    /// The chain's genesis block hash, which every signed extrinsic commits to.
    ///
    /// The node reports it (`chain_getBlockHash(0)`), but the wallet must not take the chain identity from the
    /// node it is about to trust: a node answering with another Substrate chain's genesis / block / runtime
    /// makes the user-approved transfer a valid extrinsic on that other chain (the balance-transfer call index
    /// and the recipient's raw public key are identical across these networks). Pinning the hash is the
    /// standard Substrate wallet defence. `nil` disables the check (no authoritative value confirmed).
    ///
    /// Sources: `@polkadot/networks` `knownGenesis` (polkadot, kusama, westend, aleph-node, bittensor),
    /// Joystream mainnet release v12.1000.0, Energy Web X public RPC `chain_getBlockHash(0)`.
    var genesisHash: String? {
        switch self {
        case .polkadot:
            return "0x91b171bb158e2d3848fa23a9f1c25182fb8e20313b2c1eb49219da7a70ce90c3"
        case .westend:
            return "0xe143f23803ac50e8f6f8e62695d1ce9e4e1d68aa36c1cd2cfd15340213f3423e"
        case .kusama:
            return "0xb0a8d493285c2df73290dfb7e61f870f17b41801197a149ca93654499ea3dafe"
        case .azero(_, let isTestnet):
            return isTestnet ? nil : "0x70255b4d28de0fc4e1a193d7e175ad1ccef431598211c55538f1018651a0344e"
        case .joystream:
            return "0x6b5e488e0fa8f9821110d5c13f4c468abcd43ce5e297e62b34c53c3346465956"
        case .bittensor:
            return "0x2f0555cc76fc2840a25a6ea3b9637146806f1f44b090c175ffde2a7e5ab36c03"
        case .energyWebX:
            return "0x5a51e04b88a4784d205091aa7bada002f3e5da3045e5b05655ee4db2589c33b5"
        }
    }

    var blockchainName: String {
        switch self {
        case .polkadot(let curve):
            return Blockchain.polkadot(curve: curve, testnet: false).displayName
        case .kusama(let curve):
            return Blockchain.kusama(curve: curve).displayName
        case .westend(let curve):
            return Blockchain.polkadot(curve: curve, testnet: true).displayName
        case .azero(let curve, let isTestnet):
            return Blockchain.azero(curve: curve, testnet: isTestnet).displayName
        case .joystream(let curve):
            return Blockchain.joystream(curve: curve).displayName
        case .bittensor(let curve):
            return Blockchain.bittensor(curve: curve).displayName
        case .energyWebX(let curve):
            return Blockchain.energyWebX(curve: curve).displayName
        }
    }
}

/// https://support.polkadot.network/support/solutions/articles/65000168651-what-is-the-existential-deposit-
extension PolkadotNetwork {
    var existentialDeposit: Amount {
        switch self {
        case .polkadot(let curve):
            // https://support.polkadot.network/support/solutions/articles/65000181800-what-is-asset-hub-and-how-do-i-use-it-
            return Amount(with: .polkadot(curve: curve, testnet: false), value: Decimal(stringValue: "0.01")!)
        case .kusama(let curve):
            // https://support.polkadot.network/support/solutions/articles/65000181800-what-is-asset-hub-and-how-do-i-use-it-
            return Amount(with: .kusama(curve: curve), value: Decimal(stringValue: "0.000003333")!)
        case .westend(let curve):
            // This value was found experimentally by sending transactions with different values to inactive accounts.
            // This is the lowest amount that activates an account on the Westend network.
            return Amount(with: .polkadot(curve: curve, testnet: true), value: Decimal(stringValue: "0.01")!)
        case .azero(let curve, let isTestnet):
            // Existential deposit - 0.0000000005 Look https://test.azero.dev wallet for example
            return Amount(with: .azero(curve: curve, testnet: isTestnet), value: Decimal(stringValue: "0.0000000005")!)
        case .joystream(let curve):
            // Existential deposit - 0.026666656
            // Look https://polkadot.js.org/apps/?rpc=wss%3A%2F%2Frpc.joystream.org#/accounts -> send
            return Amount(with: .joystream(curve: curve), value: Decimal(stringValue: "0.026666656")!)
        case .bittensor(let curve):
            return Amount(with: .bittensor(curve: curve), value: Decimal(stringValue: "0.0000005")!)
        case .energyWebX(let curve):
            let blockchain = Blockchain.energyWebX(curve: curve)
            return Amount(with: blockchain, value: blockchain.minimumValue)
        }
    }
}
