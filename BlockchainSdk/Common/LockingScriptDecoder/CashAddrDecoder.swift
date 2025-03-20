//
//  CashAddrDecoder.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import BitcoinCore

struct CashAddrDecoder {
    private let network: UTXONetworkParams

    init(network: UTXONetworkParams) {
        self.network = network
    }

    func decode(address: String) throws -> (version: UInt8, script: UTXOLockingScript) {
        guard let (_, data) = CashAddrBech32.decode(address) else {
            throw LockingScriptBuilderError.wrongAddress
        }

        let version = data[0]
        let keyHash = data.dropFirst()
        switch version {
        case AddressType.p2pkh.rawValue:
            let lockingStript = OpCodeUtils.p2pkh(data: keyHash)
            return (version: version, script: .init(data: lockingStript, type: .p2pkh))
        case AddressType.p2sh.rawValue:
            let lockingStript = OpCodeUtils.p2sh(data: keyHash)
            return (version: version, script: .init(data: lockingStript, type: .p2sh))
        default:
            throw LockingScriptBuilderError.unsupportedVersion
        }
    }
}

// MARK: - LockingScriptBuilder

extension CashAddrDecoder: LockingScriptBuilder {
    func lockingScript(for address: String) throws -> UTXOLockingScript {
        try decode(address: address).script
    }
}

extension CashAddrDecoder {
    enum AddressType: UInt8 {
        case p2pkh = 0x00
        case p2sh = 0x08
    }
}
