//
//  DerivationTests.swift
//  DerivationTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2019 Tangem AG. All rights reserved.
//

import Testing
@testable import BlockchainSdk

struct DerivationTests {
    @Test
    func derivationStyle() {
        let legacy: DerivationStyle = .v1
        let new: DerivationStyle = .v2

        let fantom: Blockchain = .fantom(testnet: false)
        #expect(fantom.derivationPath(for: legacy)?.rawPath == "m/44'/1007'/0'/0/0")
        #expect(fantom.derivationPath(for: new)?.rawPath == "m/44'/60'/0'/0/0")

        let eth: Blockchain = .ethereum(testnet: false)
        #expect(eth.derivationPath(for: legacy)?.rawPath == "m/44'/60'/0'/0/0")
        #expect(eth.derivationPath(for: new)?.rawPath == "m/44'/60'/0'/0/0")

        let ethTest: Blockchain = .ethereum(testnet: true)
        #expect(ethTest.derivationPath(for: legacy)?.rawPath == "m/44'/1'/0'/0/0")
        #expect(ethTest.derivationPath(for: new)?.rawPath == "m/44'/1'/0'/0/0")

        let xrp: Blockchain = .xrp(curve: .secp256k1)
        #expect(xrp.derivationPath(for: legacy)?.rawPath == "m/44'/144'/0'/0/0")
        #expect(xrp.derivationPath(for: new)?.rawPath == "m/44'/144'/0'/0/0")
    }
}
