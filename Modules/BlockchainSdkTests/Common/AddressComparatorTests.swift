//
//  AddressComparatorTests.swift
//  BlockchainSdkTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Testing
@testable import BlockchainSdk

struct AddressComparatorTests {
    private let comparator = AddressComparator()

    @Test
    func evmAddressesMatchIgnoringCase() {
        let checksummed = "0x5aAeb6053F3E94C9b9A09f33669435E7Ef1BeAed"
        let lowercased = "0x5aaeb6053f3e94c9b9a09f33669435e7ef1beaed"

        #expect(comparator.addressesMatch(checksummed, lowercased, blockchain: .ethereum(testnet: false)))
    }

    @Test
    func bitcoinLegacyAddressesDoNotMatchIgnoringCase() {
        let legacy = "1KWFv7SBZGMsneK2ZJ3D4aKcCzbvEyUbAA"

        #expect(!comparator.addressesMatch(legacy, legacy.lowercased(), blockchain: .bitcoin(testnet: false)))
    }

    @Test
    func bitcoinBech32AddressesMatchByLockingScriptAcrossAllowedCaseForms() {
        let bech32 = "bc1qxzdqcmh6pknevm2ugtw94y50dwhsu3l0p5tg63"

        #expect(comparator.addressesMatch(bech32, bech32.uppercased(), blockchain: .bitcoin(testnet: false)))
    }

    @Test
    func bitcoinCashLegacyAndCashAddrMatchByLockingScript() {
        let cashAddr = "bitcoincash:qrpgfcqrnqvp33vsex0clktvae2pqjfxnyxq0ml0zc"
        let legacy = "1JjXGY5KEcbT35uAo6P9A7DebBn4DXnjdQ"

        #expect(comparator.addressesMatch(cashAddr, legacy, blockchain: .bitcoinCash))
    }

    @Test
    func nonEVMAddressesFallbackToExactMatch() {
        let address = "GCFX4KOE4DOYZQTITL5EAZXA3CTKFS45CS6YSXO5Y4ZBZ6WZSMQ4HC3Y"

        #expect(comparator.addressesMatch(address, address, blockchain: .stellar(curve: .ed25519, testnet: false)))
        #expect(!comparator.addressesMatch(address, address.lowercased(), blockchain: .stellar(curve: .ed25519, testnet: false)))
    }
}
