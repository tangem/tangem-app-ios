//
//  ElectrumScriptHashConverter.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

struct ElectrumScriptHashConverter {
    let lockingScriptBuilder: LockingScriptBuilder

    init(lockingScriptBuilder: LockingScriptBuilder) {
        self.lockingScriptBuilder = lockingScriptBuilder
    }

    /**
     Specify electrum api network

     The hash function the server uses for script hashing. The client must use this function to hash pay-to-scripts to produce script hashes to send to the server. The default is “sha256”. “sha256” is currently the only acceptable value.

     More: https://electrumx.readthedocs.io/en/latest/protocol-basics.html#script-hashes
     */
    func prepareScriptHash(address: String) throws -> String {
        let scriptHashData = try lockingScriptBuilder.lockingScript(for: address).data

        return Data(scriptHashData.sha256().reversed()).hex(.uppercase)
    }
}
