//
//  KaspaAddressDecoder.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import class BitcoinCore.CashAddrBech32

struct KaspaAddressDecoder {
    private let bech32Prefix: String

    init(bech32Prefix: String) {
        self.bech32Prefix = bech32Prefix
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
            let lockingStript = OpCodeUtils.p2pk(data: keyHash)
            return (version: version, script: .init(data: lockingStript, type: .p2pk))
        case AddressType.p2pkhECDSA.rawValue:
            let lockingStript = OpCodeUtils.p2pkECDSA(data: keyHash)
            return (version: version, script: .init(data: lockingStript, type: .p2pk))
        case AddressType.p2sh.rawValue:
            let lockingStript = OpCodeUtils.p2sh256(data: keyHash)
            return (version: version, script: .init(data: lockingStript, type: .p2sh))
        default:
            throw LockingScriptBuilderError.unsupportedVersion
        }
    }
}

// MARK: - LockingScriptBuilder

extension KaspaAddressDecoder: LockingScriptBuilder {
    func lockingScript(for address: String) throws -> UTXOLockingScript {
        try decode(address: address).script
    }
}

extension KaspaAddressDecoder {
    enum AddressType: UInt8 {
        case p2pkhSchnorr = 0x00
        case p2pkhECDSA = 0x01
        case p2sh = 0x08
    }
}
