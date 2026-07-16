//
//  AddressBlockchainResolverTests.swift
//  TangemTests
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Testing
@testable import Tangem
@testable import BlockchainSdk

@Suite("AddressBlockchainResolver")
struct AddressBlockchainResolverTests {
    private let resolver = AddressBlockchainResolver()

    private let ethereum = Blockchain.ethereum(testnet: false)
    private let bsc = Blockchain.bsc(testnet: false)
    private let xdc = Blockchain.xdc(testnet: false)
    private let decimal = Blockchain.decimal(testnet: false)
    private let near = Blockchain.near(curve: .ed25519_slip0010, testnet: false)

    private var blockchains: [Blockchain] { [ethereum, bsc, xdc, decimal, near] }

    @Test("XDC xdc-prefixed address resolves to XDC")
    func xdcPrefixedAddressResolvesToXDC() {
        let result = resolver.resolve(address: "xdc0Ec42c2800729ECb65b748f4f3a168C958D41741", blockchains: blockchains)
        #expect(result.contains(xdc))
    }

    @Test("Decimal d0 bech32 address resolves to Decimal")
    func decimalAddressResolvesToDecimal() {
        let result = resolver.resolve(address: "d01x98ka44jmz2k7m2qy2eh7wctm0vfwep5l0uj5l", blockchains: blockchains)
        #expect(result.contains(decimal))
    }

    @Test("NEAR implicit account resolves to NEAR")
    func nearImplicitAccountResolvesToNEAR() {
        let result = resolver.resolve(
            address: "e2e1113ac2ffe8612b0212a5c960f692a2d596f468ebafaa54b776b1b731d417",
            blockchains: blockchains
        )
        #expect(result.contains(near))
    }

    @Test("NEAR named account is not resolved to NEAR")
    func nearNamedAccountIsNotResolvedToNEAR() {
        let result = resolver.resolve(address: "example.near", blockchains: blockchains)
        #expect(!result.contains(near))
    }

    @Test("Plain hex address resolves to EVM networks")
    func plainHexAddressResolvesToEVMNetworks() {
        let result = resolver.resolve(address: "0x0Ec42c2800729ECb65b748f4f3a168C958D41741", blockchains: blockchains)
        #expect(result.contains(ethereum))
        #expect(result.contains(bsc))
    }
}
