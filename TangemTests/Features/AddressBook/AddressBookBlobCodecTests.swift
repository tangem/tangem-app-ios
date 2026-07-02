//
//  AddressBookBlobCodecTests.swift
//  TangemTests
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
@testable import Tangem

@Suite("AddressBookBlobCodec")
struct AddressBookBlobCodecTests {
    private let codec = AddressBookBlobCodec()
    private let signature = Data([0xDE, 0xAD, 0xBE, 0xEF])

    private static let contactID = AddressBookContactID(rawValue: UUID(uuidString: "11111111-1111-1111-1111-111111111111")!)
    private static let secondContactID = AddressBookContactID(rawValue: UUID(uuidString: "33333333-3333-3333-3333-333333333333")!)
    private static let entryID = AddressBookAddressEntryID(rawValue: UUID(uuidString: "22222222-2222-2222-2222-222222222222")!)
    private static let secondEntryID = AddressBookAddressEntryID(rawValue: UUID(uuidString: "44444444-4444-4444-4444-444444444444")!)
    private static let thirdEntryID = AddressBookAddressEntryID(rawValue: UUID(uuidString: "55555555-5555-5555-5555-555555555555")!)

    private static let createdAt = Date(timeIntervalSince1970: 1_700_000_000)
    private static let updatedAt = Date(timeIntervalSince1970: 1_700_086_400)

    // MARK: - Round trip

    @Test
    func encodeThenDecodeRoundTripsContacts() throws {
        let alice = try makeContact(
            id: Self.contactID,
            name: "Alice",
            addresses: [
                makeEntry(id: Self.entryID, address: "0xabc", memo: "note", signature: signature),
                makeEntry(id: Self.secondEntryID, address: "0xdef", memo: nil, signature: Data([0x01, 0x02])),
            ]
        )
        let bob = try makeContact(
            id: Self.secondContactID,
            name: "Bob",
            iconColor: "CandyGreen",
            addresses: [makeEntry(id: Self.thirdEntryID, address: "0x999", memo: nil, signature: signature)]
        )
        let plaintext = AddressBookPlaintext(contacts: [alice, bob])

        let decoded = try codec.decode(codec.encode(plaintext))

        #expect(decoded == plaintext)

        #expect(decoded.contacts.map(\.name.value) == ["Alice", "Bob"])
        #expect(decoded.contacts.map(\.iconColor) == ["MexicanPink", "CandyGreen"])

        let firstDecoded = try #require(decoded.contacts.first)
        #expect(firstDecoded.addresses.map(\.address) == ["0xabc", "0xdef"])
        #expect(firstDecoded.addresses.map(\.memo) == ["note", nil])
        #expect(firstDecoded.addresses.first?.signature == signature)
    }

    @Test
    func encodeIsDeterministic() throws {
        let first = try codec.encode(AddressBookPlaintext(contacts: [makeSampleContact()]))
        let second = try codec.encode(AddressBookPlaintext(contacts: [makeSampleContact()]))
        #expect(first == second)
    }

    // MARK: - Wire format (cross-platform field names)

    @Test
    func encodedJSONUsesCrossPlatformFieldNames() throws {
        let json = try encodedJSON(for: makeSampleContact())

        for key in [
            "\"contacts\"", "\"id\"", "\"walletId\"", "\"name\"", "\"icon\"", "\"iconColor\"",
            "\"createdAt\"", "\"updatedAt\"", "\"addresses\"", "\"address\"", "\"networkId\"", "\"signature\"",
        ] {
            #expect(json.contains(key))
        }

        #expect(!json.contains("addressEntries"))
        #expect(!json.contains("icon_color"))
        #expect(!json.contains("\"version\""))
    }

    @Test
    func signatureEncodesAsBase64NotHex() throws {
        let contact = try makeContact(
            id: Self.contactID,
            name: "Alice",
            addresses: [makeEntry(id: Self.entryID, address: "0xabc", memo: "note", signature: Data([0xDE, 0xAD, 0xBE, 0xEF]))]
        )
        let json = try encodedJSON(for: contact)

        #expect(json.contains("\"3q2+7w==\""))
        #expect(!json.contains("deadbeef"))
        #expect(!json.contains("DEADBEEF"))
    }

    @Test
    func omitsMemoKeyWhenMemoIsNil() throws {
        let contact = try makeContact(
            id: Self.contactID,
            name: "Alice",
            addresses: [makeEntry(id: Self.entryID, address: "0xabc", memo: nil, signature: signature)]
        )
        let json = try encodedJSON(for: contact)
        #expect(!json.contains("\"memo\""))
    }

    // MARK: - Empty book

    @Test
    func encodesEmptyBookAsEmptyContactsArray() throws {
        let empty = AddressBookPlaintext()

        let json = String(decoding: try codec.encode(empty), as: UTF8.self)
        #expect(json == #"{"contacts":[]}"#)

        let decoded = try codec.decode(codec.encode(empty))
        #expect(decoded.contacts.isEmpty)
    }

    // MARK: - Decode (known blob)

    @Test
    func decodesAKnownBlob() throws {
        let json = """
        {"contacts":[{"addresses":[{"address":"0xabc","id":"22222222-2222-2222-2222-222222222222","memo":"note","networkId":"ethereum","signature":"3q2+7w=="}],"createdAt":"2023-11-14T22:13:20.000Z","icon":"","iconColor":"MexicanPink","id":"11111111-1111-1111-1111-111111111111","name":"Alice","updatedAt":"2023-11-15T22:13:20.000Z","walletId":"AABB"}]}
        """
        let decoded = try codec.decode(Data(json.utf8))

        let contact = try #require(decoded.contacts.first)
        #expect(decoded.contacts.count == 1)
        #expect(contact.id.stringValue == "11111111-1111-1111-1111-111111111111")
        #expect(contact.walletId == "AABB")
        #expect(contact.name.value == "Alice")
        #expect(contact.icon == "")
        #expect(contact.iconColor == "MexicanPink")

        let entry = try #require(contact.addresses.first)
        #expect(contact.addresses.count == 1)
        #expect(entry.id.stringValue == "22222222-2222-2222-2222-222222222222")
        #expect(entry.address == "0xabc")
        #expect(entry.networkId.rawValue == "ethereum")
        #expect(entry.memo == "note")
        #expect(entry.signature == Data([0xDE, 0xAD, 0xBE, 0xEF]))

        let expectedCreatedAt = try #require(AddressBookBlobCodec.date(fromISO8601: "2023-11-14T22:13:20.000Z"))
        #expect(contact.createdAt == expectedCreatedAt)
    }

    // MARK: - Date parsing

    @Test
    func parsesWholeSecondTimestampViaFallbackFormatter() {
        let fractional = AddressBookBlobCodec.date(fromISO8601: "2023-11-14T22:13:20.000Z")
        let wholeSecond = AddressBookBlobCodec.date(fromISO8601: "2023-11-14T22:13:20Z")

        #expect(fractional != nil)
        #expect(wholeSecond != nil)
        #expect(fractional == wholeSecond)
    }

    @Test
    func returnsNilForAnUnparsableTimestamp() {
        #expect(AddressBookBlobCodec.date(fromISO8601: "not-a-date") == nil)
    }

    // MARK: - Fixtures

    private func makeName(_ value: String) throws -> AddressBookContactName {
        try AddressBookContactNameValidator().validate(value)
    }

    private func makeEntry(
        id: AddressBookAddressEntryID,
        address: String,
        networkId: String = "ethereum",
        memo: String?,
        signature: Data
    ) -> AddressBookDecodedAddressEntry {
        AddressBookDecodedAddressEntry(
            id: id,
            address: address,
            networkId: AddressBookNetworkID(networkId),
            memo: memo,
            signature: signature
        )
    }

    private func makeContact(
        id: AddressBookContactID,
        name value: String,
        iconColor: String = "MexicanPink",
        addresses: [AddressBookDecodedAddressEntry]
    ) throws -> AddressBookDecodedContact {
        AddressBookDecodedContact(
            id: id,
            walletId: "AABBCCDD",
            name: try makeName(value),
            icon: "",
            iconColor: iconColor,
            createdAt: Self.createdAt,
            updatedAt: Self.updatedAt,
            addresses: addresses
        )
    }

    private func makeSampleContact() throws -> AddressBookDecodedContact {
        try makeContact(
            id: Self.contactID,
            name: "Alice",
            addresses: [makeEntry(id: Self.entryID, address: "0xabc", memo: "note", signature: signature)]
        )
    }

    private func encodedJSON(for contact: AddressBookDecodedContact) throws -> String {
        String(decoding: try codec.encode(AddressBookPlaintext(contacts: [contact])), as: UTF8.self)
    }
}
