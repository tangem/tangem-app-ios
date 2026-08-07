//
//  AddressBookNetworkMapperTests.swift
//  TangemTests
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
import TangemSdk
import TangemFoundation
@testable import Tangem

private let validWalletIdHex = String(repeating: "A1", count: 32)
private let validNonceHex = "000102030405060708090A0B"
private let validCiphertextHex = "AABBCCDDEE"
private let validTagHex = String(repeating: "5A", count: 16)
private let validUpdatedAtString = "2026-06-30T12:00:00.000Z"

@Suite("AddressBookNetworkMapper")
struct AddressBookNetworkMapperTests {
    private let mapper = AddressBookNetworkMapper()

    private let walletIdValue = Data(repeating: 0xA1, count: 32)
    private let nonce = Data((0 ..< 12).map { UInt8($0) })
    private let ciphertext = Data([0xAA, 0xBB, 0xCC, 0xDD, 0xEE])
    private let tag = Data(repeating: 0x5A, count: 16)
    private let updatedAt = AddressBookBlobCodec.date(fromISO8601: validUpdatedAtString)!

    private var envelope: AddressBookEnvelope {
        AddressBookEnvelope(
            version: "1.0",
            walletId: UserWalletId(value: walletIdValue),
            updatedAt: updatedAt,
            sealedBox: AddressBookSealedBox(nonce: nonce, ciphertext: ciphertext, tag: tag)
        )
    }

    // MARK: - Hex encode / decode

    @Test
    func mapToDTOEmitsUppercaseHexForBinaryFields() {
        let dto = mapper.mapToDTO(envelope)

        #expect(dto.walletId == envelope.walletId.stringValue)
        #expect(dto.nonce == nonce.hexString)
        #expect(dto.ciphertext == ciphertext.hexString)
        #expect(dto.authTag == tag.hexString)
        #expect(dto.nonce == dto.nonce.uppercased())
        #expect(dto.authTag == dto.authTag.uppercased())
    }

    @Test
    func mapToEnvelopeDecodesHexCaseInsensitively() throws {
        let lower = try mapper.mapToEnvelope(makeEnvelopeDTO(
            nonce: "000102030405060708090a0b",
            authTag: String(repeating: "5a", count: 16)
        ))
        let upper = try mapper.mapToEnvelope(makeEnvelopeDTO(
            nonce: "000102030405060708090A0B",
            authTag: String(repeating: "5A", count: 16)
        ))

        #expect(lower.sealedBox.nonce == nonce)
        #expect(lower.sealedBox.tag == tag)
        #expect(lower == upper)
    }

    // MARK: - Envelope <-> DTO round trip

    @Test
    func envelopeRoundTripsThroughDTO() throws {
        let restored = try mapper.mapToEnvelope(mapper.mapToDTO(envelope))
        #expect(restored == envelope)
    }

    @Test
    func mapToEnvelopeFromResponseItemCarriesETag() throws {
        let item = AddressBookDTO.Response.Item(
            walletId: validWalletIdHex,
            etag: "etag-7",
            version: "1.0",
            updatedAt: validUpdatedAtString,
            nonce: validNonceHex,
            ciphertext: validCiphertextHex,
            authTag: validTagHex
        )

        let remote = try mapper.mapToEnvelope(item)

        #expect(remote.etag == "etag-7")
        #expect(remote.envelope == envelope)
    }

    @Test
    func mapToUpdateRequestCarriesVersionAndHexBinaryFields() {
        let request = mapper.mapToUpdateRequest(envelope)

        #expect(request.version == "1.0")
        #expect(request.nonce == nonce.hexString)
        #expect(request.ciphertext == ciphertext.hexString)
        #expect(request.authTag == tag.hexString)
    }

    // MARK: - updatedAt parse / format

    @Test
    func updatedAtRoundTripsThroughISO8601FractionalSeconds() throws {
        let dto = mapper.mapToDTO(envelope)

        #expect(dto.updatedAt == "2026-06-30T12:00:00.000Z")

        let restored = try mapper.mapToEnvelope(dto)
        #expect(restored.updatedAt == updatedAt)
    }

    @Test
    func mapToSaveResultParsesUpdatedAtAndCarriesETag() throws {
        let response = AddressBookDTO.UpdateResponse(
            walletId: validWalletIdHex,
            updatedAt: validUpdatedAtString,
            etag: "etag-42"
        )

        let result = try mapper.mapToSaveResult(response)

        #expect(result.etag == "etag-42")
        #expect(result.updatedAt == AddressBookBlobCodec.date(fromISO8601: validUpdatedAtString))
    }

    @Test
    func mapToSaveResultThrowsOnUnparsableUpdatedAt() {
        let response = AddressBookDTO.UpdateResponse(
            walletId: validWalletIdHex,
            updatedAt: "not-a-date",
            etag: "etag"
        )

        let error = #expect(throws: AddressBookNetworkMapper.MappingError.self) {
            try mapper.mapToSaveResult(response)
        }
        guard case .unparsableUpdatedAt(let value)? = error else {
            Issue.record("Expected .unparsableUpdatedAt, got \(String(describing: error))")
            return
        }
        #expect(value == "not-a-date")
    }

    @Test
    func invalidUpdatedAtThrowsInvalidDate() {
        let error = #expect(throws: AddressBookNetworkMapper.MappingError.self) {
            try mapper.mapToEnvelope(makeEnvelopeDTO(updatedAt: "not-a-date"))
        }
        guard case .invalidDate(let value)? = error else {
            Issue.record("Expected .invalidDate, got \(String(describing: error))")
            return
        }
        #expect(value == "not-a-date")
    }

    // MARK: - Length validation

    @Test
    func nonceWithWrongLengthThrowsInvalidLength() {
        let error = #expect(throws: AddressBookNetworkMapper.MappingError.self) {
            try mapper.mapToEnvelope(makeEnvelopeDTO(nonce: String(repeating: "AB", count: 11)))
        }
        guard case .invalidLength(let field, let expected, let actual)? = error else {
            Issue.record("Expected .invalidLength for nonce, got \(String(describing: error))")
            return
        }
        #expect(field == .nonce)
        #expect(expected == 12)
        #expect(actual == 11)
    }

    @Test
    func authTagWithWrongLengthThrowsInvalidLength() {
        let error = #expect(throws: AddressBookNetworkMapper.MappingError.self) {
            try mapper.mapToEnvelope(makeEnvelopeDTO(authTag: String(repeating: "CD", count: 15)))
        }
        guard case .invalidLength(let field, let expected, let actual)? = error else {
            Issue.record("Expected .invalidLength for authTag, got \(String(describing: error))")
            return
        }
        #expect(field == .authTag)
        #expect(expected == 16)
        #expect(actual == 15)
    }

    // MARK: - Invalid hex

    @Test
    func invalidHexInCiphertextThrowsInvalidHex() {
        let error = #expect(throws: AddressBookNetworkMapper.MappingError.self) {
            try mapper.mapToEnvelope(makeEnvelopeDTO(ciphertext: "zz"))
        }
        guard case .invalidHex(let field)? = error else {
            Issue.record("Expected .invalidHex, got \(String(describing: error))")
            return
        }
        #expect(field == .ciphertext)
    }

    @Test
    func invalidHexInWalletIdThrowsInvalidHex() {
        let error = #expect(throws: AddressBookNetworkMapper.MappingError.self) {
            try mapper.mapToEnvelope(makeEnvelopeDTO(walletId: "zz"))
        }
        guard case .invalidHex(let field)? = error else {
            Issue.record("Expected .invalidHex, got \(String(describing: error))")
            return
        }
        #expect(field == .walletId)
    }

    // MARK: - Fixtures

    private func makeEnvelopeDTO(
        version: String = "1.0",
        walletId: String = validWalletIdHex,
        updatedAt: String = validUpdatedAtString,
        nonce: String = validNonceHex,
        ciphertext: String = validCiphertextHex,
        authTag: String = validTagHex
    ) -> AddressBookDTO.Envelope {
        AddressBookDTO.Envelope(
            version: version,
            walletId: walletId,
            updatedAt: updatedAt,
            nonce: nonce,
            ciphertext: ciphertext,
            authTag: authTag
        )
    }
}
