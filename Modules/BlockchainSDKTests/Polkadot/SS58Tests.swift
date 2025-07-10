//
//  SS58Tests.swift
//  BlockchainSdkTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Testing
@testable import BlockchainSdk

/// Hardcoded addresses provided via 'subkey' command line tool
/// either 'subkey generate -n <network>'
/// or 'subkey inspect --public <hex address> -n <network>'
struct SS58Tests {
    private let ss58 = SS58()

    @Test
    func publicKeyIsLessOrEqualThan32Bytes() {
        let data1 = Data(hex: "0x1")
        let addressData1 = ss58.accountData(from: data1)

        #expect(data1 == addressData1)

        let data2 = Data(hex: "0xB7D152D0703FAD867AFCB9F6E12F223C88A7592BF640547A620CFFAA91E0D06E") // 32-byte
        let addressData2 = ss58.accountData(from: data2)

        #expect(data2 == addressData2)
    }

    @Test
    func testPublicKeyIsGreaterThan32Bytes() {
        let data = Data(hex: "0x215AF345DBE3C884B6CC7C96F906731393515E3B2DC9FB28D7C896369AB930ADA1") // 33-byte

        let addressData = ss58.accountData(from: data)

        #expect(addressData != nil)
        #expect(data != addressData)
    }

    @Test
    func testNetworkTypesFromAddresses() throws {
        let polkadotAddress = "14iZ16K231zixpvaca4t2jMmt5DeDqeqTgfBBFCE3oUcA7v1"
        let polkadotNetworkType = try ss58.networkType(from: polkadotAddress)

        #expect(polkadotNetworkType == 0)

        let kusamaAddress = "CjPfzHY5h3ZLftZwfqFTKPufCVEo9Tjm4tanfDg5wW3KfM8"
        let kusamaNetworkType = try ss58.networkType(from: kusamaAddress)

        #expect(kusamaNetworkType == 2)

        // azero uses generic substrate addresses
        let azeroAddress = "5FndavgJ6H2KnHUZ8C7u5QAFThV3Se2z3E4nanMCYJtZKSh8"
        let azeroNetworkType = try ss58.networkType(from: azeroAddress)

        #expect(azeroNetworkType == 42)

        let joystreamAddress = "j4UW8myxisJrqbiGPah1vsf9ka3soLpGRLdUPS9Fdi8sFGXMa"
        let joystreamNetworkType = try ss58.networkType(from: joystreamAddress)

        #expect(joystreamNetworkType == 126)
    }

    @Test
    func networkTypeThrowsError() {
        let polkadotAddress = "1" // too short address

        #expect(throws: (any Error).self) {
            try ss58.networkType(from: polkadotAddress)
        }
    }

    @Test
    func generateAddresses() {
        let hexString = "0x80C1B49CA830D61FCC69256C26BB5EF6A3F0E198A7A981365F038BBA42266ED7"
        let accountData = Data(hex: hexString)

        let polkadotAddress = ss58.address(from: accountData, type: 0)
        #expect(polkadotAddress == "13upfxwAepTxvfEEkSp567AXypn9ym5NGxsWmhdyxHXw5ocz")

        let kusamaAddress = ss58.address(from: accountData, type: 2)
        #expect(kusamaAddress == "FV9Bx1yRQDREn3AZWa7quhPGo4k68LQeqyn14vasziueRF2")

        // azero uses generic substrate addresses
        let alephZeroAddress = ss58.address(from: accountData, type: 42)
        #expect(alephZeroAddress == "5EyXXdg6o3CVV8Dinom4wxLP8CnWHTXECU92cQedQCWQuNtp")

        let joystreamAddress = ss58.address(from: accountData, type: 126)
        #expect(joystreamAddress == "j4UES6fv4fkhXKjfU4nCko73Neas5nM6PvQmTyxgwqGf3Yr1F")

        let cessAddress = ss58.address(from: accountData, type: 11331)
        #expect(cessAddress == "ce6GhSBHQMxgzSftDsq67a4XWfjBgxPBux9HTw8ZHr7ZHFJQf")
    }

    @Test
    func isValidAddressTrue() {
        let polkadotAddress = "13upfxwAepTxvfEEkSp567AXypn9ym5NGxsWmhdyxHXw5ocz"
        #expect(ss58.isValidAddress(polkadotAddress, type: 0))

        let kusamaAddress = "FV9Bx1yRQDREn3AZWa7quhPGo4k68LQeqyn14vasziueRF2"
        #expect(ss58.isValidAddress(kusamaAddress, type: 2))

        // azero uses generic substrate addresses
        let alephZeroAddress = "5EyXXdg6o3CVV8Dinom4wxLP8CnWHTXECU92cQedQCWQuNtp"
        #expect(ss58.isValidAddress(alephZeroAddress, type: 42))

        let joystreamAddress = "j4UES6fv4fkhXKjfU4nCko73Neas5nM6PvQmTyxgwqGf3Yr1F"
        #expect(ss58.isValidAddress(joystreamAddress, type: 126))
    }

    @Test
    func isValidAddressFalse() {
        let invalidPolkadotAddress = "13upfxwAepTxvfEEkSp567Xypn9ym5NGxsWmhdyxHXw5ocz"
        #expect(!ss58.isValidAddress(invalidPolkadotAddress, type: 0))

        let invalidKusamaAddress = "FV9Bx1yRQDREn3AZWa7quhPG4k68LQeqyn14vasziueRF2"
        #expect(!ss58.isValidAddress(invalidKusamaAddress, type: 2))

        // azero uses generic substrate addresses
        let invalidAlephZeroAddress = "5EyXXdg6o3CVV8Dinom4w55LP8CnWHTXECU92cQedQCWQuNtp"
        #expect(!ss58.isValidAddress(invalidAlephZeroAddress, type: 42))

        let invalidJoystreamAddress = "j4UES6fv4fkhXKjfU4nCk55o73Neas5nM6PvQmTyxgwqGf3Yr1F"
        #expect(!ss58.isValidAddress(invalidJoystreamAddress, type: 126))

        let validPolkadotAddress = "13upfxwAepTxvfEEkSp567AXypn9ym5NGxsWmhdyxHXw5ocz"
        #expect(!ss58.isValidAddress(validPolkadotAddress, type: 1))
    }

    @Test
    func rawBytesFalse() {
        let polkadotAddress = "13upfxwAepTxvfEEkSp567AXypn9ym5NGxsWmhdyxHXw5ocz"

        let bytes = ss58.bytes(string: polkadotAddress, raw: false)
        #expect(bytes.hex(.uppercase) == "0080C1B49CA830D61FCC69256C26BB5EF6A3F0E198A7A981365F038BBA42266ED7")
    }

    @Test
    func rawBytesTrue() {
        let polkadotAddress = "13upfxwAepTxvfEEkSp567AXypn9ym5NGxsWmhdyxHXw5ocz"

        let bytes = ss58.bytes(string: polkadotAddress, raw: true)
        #expect(bytes.hex(.uppercase) == "80C1B49CA830D61FCC69256C26BB5EF6A3F0E198A7A981365F038BBA42266ED7")
    }
}
