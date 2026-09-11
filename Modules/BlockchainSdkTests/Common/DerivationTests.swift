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

        let gonka: Blockchain = .gonka(testnet: false)
        #expect(gonka.derivationPath(for: legacy)?.rawPath == "m/44'/1200'/0'/0/0")
        #expect(gonka.derivationPath(for: new)?.rawPath == "m/44'/1200'/0'/0/0")
        #expect(gonka.derivationPath(for: .v3)?.rawPath == "m/44'/1200'/0'/0/0")

        let electroneum: Blockchain = .electroneum(testnet: false)
        #expect(electroneum.derivationPath(for: legacy)?.rawPath == "m/44'/415'/0'/0/0")
        #expect(electroneum.derivationPath(for: new)?.rawPath == "m/44'/60'/0'/0/0")
        #expect(electroneum.derivationPath(for: .v3)?.rawPath == "m/44'/60'/0'/0/0")

        let arc: Blockchain = .arc(testnet: false)
        #expect(arc.derivationPath(for: legacy)?.rawPath == "m/44'/5042'/0'/0/0")
        #expect(arc.derivationPath(for: new)?.rawPath == "m/44'/60'/0'/0/0")
        #expect(arc.derivationPath(for: .v3)?.rawPath == "m/44'/60'/0'/0/0")
    }
}
