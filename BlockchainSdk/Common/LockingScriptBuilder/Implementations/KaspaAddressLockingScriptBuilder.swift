//
//  KaspaAddressLockingScriptBuilder.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

struct KaspaAddressLockingScriptBuilder {
    private let p2pkhPrefix: UInt8
    private let bech32Prefix: String

    init(network: UTXONetworkParams) {
        p2pkhPrefix = network.p2pkhPrefix
        bech32Prefix = network.bech32Prefix
    }

    func decode(address: String) throws -> (version: UInt8, script: UTXOLockingScript) {
        guard let (prefix, data) = CashAddrBech32.decode(address) else {
            throw LockingScriptBuilderError.wrongAddress
        }

        guard bech32Prefix == prefix else {
            throw LockingScriptBuilderError.wrongAddress
        }

        let version = data[0]
        let keyHash = data.dropFirst()
        switch version {
        case AddressType.p2pkhSchnorr.rawValue:
            let lockingScript = OpCodeUtils.p2pk(data: keyHash)
            return (version: version, script: .init(data: lockingScript, type: .p2pk, spendable: .none))
        case AddressType.p2pkhECDSA.rawValue:
            let lockingScript = OpCodeUtils.p2pkECDSA(data: keyHash)
            return (version: version, script: .init(data: lockingScript, type: .p2pk, spendable: .none))
        case AddressType.p2sh.rawValue:
            let lockingScript = OpCodeUtils.p2sh256(data: keyHash)
            return (version: version, script: .init(data: lockingScript, type: .p2sh, spendable: .none))
        default:
            throw LockingScriptBuilderError.unsupportedVersion
        }
    }

    func encode(publicKey: Data, type: UTXOScriptType) throws -> (address: String, script: UTXOLockingScript) {
        let lockingScript: UTXOLockingScript = try {
            switch type {
            case .p2pk where p2pkhPrefix == AddressType.p2pkhSchnorr.rawValue:
                let lockingScript = OpCodeUtils.p2pk(data: publicKey)
                return UTXOLockingScript(data: lockingScript, type: .p2pk, spendable: .publicKey(publicKey))
            case .p2pk where p2pkhPrefix == AddressType.p2pkhECDSA.rawValue:
                let lockingScript = OpCodeUtils.p2pkECDSA(data: publicKey)
                return UTXOLockingScript(data: lockingScript, type: .p2pk, spendable: .publicKey(publicKey))
            case .p2sh:
                let keyHash = publicKey.sha256Ripemd160
                let lockingScript = OpCodeUtils.p2sh256(data: keyHash)
                return UTXOLockingScript(data: lockingScript, type: .p2sh, spendable: .publicKey(publicKey))
            default:
                throw LockingScriptBuilderError.unsupportedVersion
            }
        }()

        let address = CashAddrBech32.encode(p2pkhPrefix.data + publicKey, prefix: bech32Prefix)
        return (address: address, script: lockingScript)
    }
}

// MARK: - LockingScriptBuilder

extension KaspaAddressLockingScriptBuilder: LockingScriptBuilder {
    func lockingScript(for address: String) throws -> UTXOLockingScript {
        try decode(address: address).script
    }
}

extension KaspaAddressLockingScriptBuilder {
    enum AddressType: UInt8 {
        case p2pkhSchnorr = 0x00
        case p2pkhECDSA = 0x01
        case p2sh = 0x08
    }
}
