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

        let evmChains: [(blockchain: Blockchain, legacyPath: String)] = [
            (.ethereum(testnet: false), "m/44'/60'/0'/0/0"),
            (.fantom(testnet: false), "m/44'/1007'/0'/0/0"),
            (.electroneum(testnet: false), "m/44'/415'/0'/0/0"),
            (.arc(testnet: false), "m/44'/5042'/0'/0/0"),
            (.publicMasterpiece, "m/44'/60'/0'/0/0"),
            (.onyx(testnet: false), "m/44'/60'/0'/0/0"),
            (.zeniq, "m/44'/60'/0'/0/0"),
            (.katana(testnet: false), "m/44'/60'/0'/0/0"),
            (.xLayer(testnet: false), "m/44'/60'/0'/0/0"),
            (.ink(testnet: false), "m/44'/60'/0'/0/0"),
        ]

        for (blockchain, legacyPath) in evmChains {
            #expect(blockchain.derivationPath(for: legacy)?.rawPath == legacyPath)
            #expect(blockchain.derivationPath(for: new)?.rawPath == "m/44'/60'/0'/0/0")
            #expect(blockchain.derivationPath(for: .v3)?.rawPath == "m/44'/60'/0'/0/0")
        }

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
    }
}
