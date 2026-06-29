//
//  AddressBookNetworkMapper.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk
import TangemFoundation

/// Maps between the wire DTOs and the domain envelope. It never decrypts — the crypto layer owns the
/// plaintext. Keeps the wire contract in one place for both the network service and the local cache.
struct AddressBookNetworkMapper {
    enum MappingError: Error {
        case invalidHex(field: EnvelopeHexField)
        case invalidLength(field: EnvelopeHexField, expected: Int, actual: Int)
        case invalidDate(String)
    }

    /// The hex-encoded binary fields of an envelope, named for diagnostics on malformed input.
    enum EnvelopeHexField: String {
        case walletId
        case nonce
        case ciphertext
        case authTag
    }

    /// AES-256-GCM uses a 12-byte nonce and a 16-byte authentication tag. Enforcing the lengths here
    /// surfaces a malformed envelope as a precise mapping error instead of a generic authentication
    /// failure deep in the crypto layer.
    private static let gcmNonceLength = 12
    private static let gcmTagLength = 16

    func mapToEnvelope(_ item: AddressBookDTO.Response.Item) throws -> RemoteAddressBook {
        let envelope = try makeEnvelope(
            version: AddressBookBlobCodec.supportedVersion,
            walletId: item.walletId,
            updatedAt: item.updatedAt,
            nonce: item.nonce,
            ciphertext: item.ciphertext,
            authTag: item.authTag
        )

        return RemoteAddressBook(etag: item.etag, envelope: envelope)
    }

    func mapToEnvelope(_ dto: AddressBookDTO.Envelope) throws -> AddressBookEnvelope {
        try makeEnvelope(
            version: dto.version,
            walletId: dto.walletId,
            updatedAt: dto.updatedAt,
            nonce: dto.nonce,
            ciphertext: dto.ciphertext,
            authTag: dto.authTag
        )
    }

    func mapToDTO(_ envelope: AddressBookEnvelope) -> AddressBookDTO.Envelope {
        AddressBookDTO.Envelope(
            version: envelope.version,
            walletId: envelope.walletId.stringValue,
            updatedAt: AddressBookBlobCodec.dateFormatter.string(from: envelope.updatedAt),
            nonce: envelope.sealedBox.nonce.hexString,
            ciphertext: envelope.sealedBox.ciphertext.hexString,
            authTag: envelope.sealedBox.tag.hexString
        )
    }

    func mapToUpdateRequest(_ envelope: AddressBookEnvelope) -> AddressBookDTO.UpdateRequest {
        AddressBookDTO.UpdateRequest(
            version: envelope.version,
            nonce: envelope.sealedBox.nonce.hexString,
            ciphertext: envelope.sealedBox.ciphertext.hexString,
            authTag: envelope.sealedBox.tag.hexString
        )
    }

    private func makeEnvelope(
        version: String,
        walletId: String,
        updatedAt: String,
        nonce: String,
        ciphertext: String,
        authTag: String
    ) throws -> AddressBookEnvelope {
        guard let date = AddressBookBlobCodec.date(fromISO8601: updatedAt) else {
            throw MappingError.invalidDate(updatedAt)
        }

        let walletIdData = try data(fromHex: walletId, field: .walletId)

        let sealedBox = try AddressBookSealedBox(
            nonce: data(fromHex: nonce, field: .nonce, expectedLength: Self.gcmNonceLength),
            ciphertext: data(fromHex: ciphertext, field: .ciphertext),
            tag: data(fromHex: authTag, field: .authTag, expectedLength: Self.gcmTagLength)
        )

        return AddressBookEnvelope(
            version: version,
            walletId: UserWalletId(value: walletIdData),
            updatedAt: date,
            sealedBox: sealedBox
        )
    }

    private func data(fromHex hex: String, field: EnvelopeHexField, expectedLength: Int? = nil) throws -> Data {
        let data = Data(hexString: hex)

        guard !data.isEmpty else {
            throw MappingError.invalidHex(field: field)
        }

        if let expectedLength, data.count != expectedLength {
            throw MappingError.invalidLength(field: field, expected: expectedLength, actual: data.count)
        }

        return data
    }
}
