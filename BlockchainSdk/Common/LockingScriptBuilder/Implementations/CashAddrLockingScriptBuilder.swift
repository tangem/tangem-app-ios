//
//  CashAddrLockingScriptBuilder.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

struct CashAddrLockingScriptBuilder {
    private let bech32Prefix: String

    init(network: UTXONetworkParams) {
        bech32Prefix = network.bech32Prefix
    }

    func decode(address: String) throws -> (version: UInt8, script: UTXOLockingScript) {
        guard let (prefix, data) = CashAddrBech32.decode(address) else {
            throw LockingScriptBuilderError.wrongAddress
        }

        guard prefix == bech32Prefix else {
            throw LockingScriptBuilderError.wrongBech32Prefix
        }

        let version = data[0]
        let keyHash = data.dropFirst()
        switch version {
        case AddressType.p2pkh.rawValue:
            let lockingScript = OpCodeUtils.p2pkh(data: keyHash)
            return (version: version, script: .init(data: lockingScript, type: .p2pkh, spendable: .none))
        case AddressType.p2sh.rawValue:
            let lockingScript = OpCodeUtils.p2sh(data: keyHash)
            // We don't have redeemScript from address. Only from PublicKey
            return (version: version, script: .init(data: lockingScript, type: .p2sh, spendable: .none))
        default:
            throw LockingScriptBuilderError.unsupportedVersion
        }
    }
}

// MARK: - LockingScriptBuilder

extension CashAddrLockingScriptBuilder: LockingScriptBuilder {
    func lockingScript(for address: String) throws -> UTXOLockingScript {
        try decode(address: address).script
    }
}

extension CashAddrLockingScriptBuilder {
    enum AddressType: UInt8 {
        case p2pkh = 0x00
        case p2sh = 0x08
    }
}
