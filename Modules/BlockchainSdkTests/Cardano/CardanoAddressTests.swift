//
//  CardanoAddressTests.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk
import CryptoKit
import class WalletCore.PrivateKey
@testable import BlockchainSdk
import Testing

struct CardanoAddressTests {
    let service = AddressServiceFactory(blockchain: .cardano(extended: false)).makeAddressService()
    let extendedService = AddressServiceFactory(blockchain: .cardano(extended: true)).makeAddressService()

    @Test
    func byronAddressGeneration() throws {
        // when
        let addrs = try service.makeAddress(from: Keys.AddressesKeys.edKey, type: .legacy)

        // then
        #expect(addrs.localizedName == AddressType.legacy.defaultLocalizedName)
        #expect(addrs.value == "Ae2tdPwUPEZAwboh4Qb8nzwQe6kmT5A3EmGKAKuS6Tcj8UkHy6BpQFnFnND")
        #expect(throws: (any Error).self) {
            try service.makeAddress(from: Keys.AddressesKeys.secpCompressedKey)
        }
        #expect(throws: (any Error).self) {
            try service.makeAddress(from: Keys.AddressesKeys.secpDecompressedKey)
        }
    }

    @Test
    func shelleyAddressGeneration() throws {
        // when
        let addrs_shelley = try service.makeAddress(from: Keys.AddressesKeys.edKey, type: .default) // default is shelley
        let addrs_byron = try service.makeAddress(from: Keys.AddressesKeys.edKey, type: .legacy) // legacy is byron

        // then
        #expect(addrs_byron.localizedName == AddressType.legacy.defaultLocalizedName)
        #expect(addrs_byron.value == "Ae2tdPwUPEZAwboh4Qb8nzwQe6kmT5A3EmGKAKuS6Tcj8UkHy6BpQFnFnND")

        #expect(addrs_shelley.localizedName == AddressType.default.defaultLocalizedName)
        #expect(addrs_shelley.value == "addr1vyq5f2ntspszzu77guh8kg4gkhzerws5t9jd6gg4d222yfsajkfw5")

        #expect(throws: (any Error).self) {
            try service.makeAddress(from: Keys.AddressesKeys.secpCompressedKey)
        }
        #expect(throws: (any Error).self) {
            try service.makeAddress(from: Keys.AddressesKeys.secpDecompressedKey)
        }
    }

    @Test("Enterprise, base and Byron addresses pass both validators", arguments: Self.honestAddresses)
    func honestAddressIsAccepted(address: String) {
        #expect(service.validate(address))
        #expect(extendedService.validate(address))
    }

    @Test("A Shelley string whose bech32 HRP is not \"addr\" is rejected by both validators", arguments: Self.forgedShelleyAddresses)
    func forgedShelleyAddressIsRejected(address: String) {
        #expect(!service.validate(address))
        #expect(!extendedService.validate(address))
    }

    @Test("The Byron fixture items reassemble the honest Byron address")
    func byronFixtureItemsReassembleHonestAddress() {
        #expect(Self.address(fromCBORHex: "82" + Self.byronPayloadItemHex + Self.byronChecksumItemHex) == Self.byronAddress)
    }

    @Test("\"3D\", the Base58 form of an empty CBOR array, is rejected")
    func threeDIsRejected() {
        #expect("3D".base58DecodedBytes == [0x80])
        #expect(!service.validate("3D"))
    }

    @Test("A Byron candidate whose CBOR array holds fewer than two items is rejected", arguments: Self.arraysWithFewerThanTwoItems)
    func arrayWithFewerThanTwoItemsIsRejected(cborHex: String) {
        #expect(!service.validate(Self.address(fromCBORHex: cborHex)))
    }

    @Test("A Byron candidate whose CBOR head declares far more content than follows is rejected", arguments: Self.headsDeclaringHugeLengths)
    func hugeDeclaredLengthIsRejected(cborHex: String) {
        #expect(!service.validate(Self.address(fromCBORHex: cborHex)))
    }

    @Test("A Byron candidate nested over a thousand levels deep is rejected without overflowing the stack", arguments: CBORNestingHead.allCases)
    func deeplyNestedCandidateIsRejected(head: CBORNestingHead) {
        let cborHex = String(repeating: head.rawValue, count: 1_024) + "00"

        #expect(!service.validate(Self.address(fromCBORHex: cborHex)))
    }

    @Test("A Byron address with an extra item nested down to the depth cap still passes, so the rejection one level deeper comes from depth alone")
    func trailingItemNestedToDepthCapIsAccepted() {
        #expect(service.validate(Self.byronAddress(withTrailingItemNestedTo: Self.byronDepthCap)))
    }

    @Test("A Byron address with an extra item nested one level past the depth cap is rejected, though it fails no other check")
    func trailingItemNestedPastDepthCapIsRejected() {
        #expect(!service.validate(Self.byronAddress(withTrailingItemNestedTo: Self.byronDepthCap + 1)))
    }
}

// MARK: - Fixtures

private extension CardanoAddressTests {
    static let payeeEnterpriseAddress = "addr1vyq5f2ntspszzu77guh8kg4gkhzerws5t9jd6gg4d222yfsajkfw5"
    static let payeeBaseAddress = "addr1q90uh2eawrdc9vaemftgd50l28yrh9lqxtjjh4z6dnn0u7ggasexxdyyk9f05atygnjlccsjsggtc87hhqjna32fpv5qeq96ls"
    static let byronAddress = "Ae2tdPwUPEZAwboh4Qb8nzwQe6kmT5A3EmGKAKuS6Tcj8UkHy6BpQFnFnND"

    static let honestAddresses = [payeeEnterpriseAddress, payeeBaseAddress, byronAddress]

    static let forgedShelleyAddresses = [
        payeeEnterpriseAddress + "1vyn5mah4qzseuaxt5tj7sd5qf8rahy63ypzt3k4rvzvlzsghctmp7",
        "addr11vyn5mah4qzseuaxt5tj7sd5qf8rahy63ypzt3k4rvzvlzsggwzmd5",
        payeeEnterpriseAddress + "1vyn5mah4qzseuaxt5tj7sd5qf8rahy63ypzt3k4rvzvlzsgzymhyu",
        payeeEnterpriseAddress + "1w89res42a6qj0skt5hlmlyvvxzy6lh0wacnyzun9pz960ccpucf3j",
        String(payeeBaseAddress.prefix(66)) + "1vyn5mah4qzseuaxt5tj7sd5qf8rahy63ypzt3k4rvzvlzsg3rkhag",
    ]

    static let byronPayloadItemHex = "d818582183581c8da9bc694ce6c8b156c9c7d398385cef33fd98f90df4e61d2d12d97aa000"
    static let byronChecksumItemHex = "1af8f67622"

    static let arraysWithFewerThanTwoItems = [
        "9fff",
        "8100",
        "81" + byronPayloadItemHex,
        "9f" + byronPayloadItemHex + "ff",
        "81" + byronPayloadItemHex + byronChecksumItemHex,
    ]

    static let hugeLengthHex = "0001000000000000"

    static let headsDeclaringHugeLengths = [
        "9a" + "ffffffff",
        "9b" + hugeLengthHex,
        "9b" + "7fffffffffffffff",
        "9b" + "ffffffffffffffff",
        "9b" + hugeLengthHex + byronPayloadItemHex + byronChecksumItemHex,
        "82" + "9b" + hugeLengthHex,
        "82" + byronPayloadItemHex + "9b" + hugeLengthHex,
        "82" + "d818" + "5b" + hugeLengthHex,
        "bb" + hugeLengthHex,
    ]

    static let byronDepthCap = 8
}

extension CardanoAddressTests {
    enum CBORNestingHead: String, CaseIterable {
        case array = "81"
        case indefiniteLengthArray = "9f"
        case map = "a1"
        case tag = "c6"
    }
}

// MARK: - Helpers

private extension CardanoAddressTests {
    static func address(fromCBORHex cborHex: String) -> String {
        Data(hexString: cborHex).base58EncodedString
    }

    static func byronAddress(withTrailingItemNestedTo level: Int) -> String {
        let trailingItem = String(repeating: "81", count: level - 1) + "80"

        return address(fromCBORHex: "83" + byronPayloadItemHex + byronChecksumItemHex + trailingItem)
    }
}
