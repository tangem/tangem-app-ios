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

struct AddressBookNetworkMapper {
    enum MappingError: LocalizedError {
        case invalidHex(field: EnvelopeHexField)
        case invalidLength(field: EnvelopeHexField, expected: Int, actual: Int)
        case invalidDate(String)
        case unparsableUpdatedAt(String)

        var errorDescription: String? {
            switch self {
            case .invalidHex(let field):
                "Address book \(field.rawValue) is not valid hex"
            case .invalidLength(let field, let expected, let actual):
                "Address book \(field.rawValue) has wrong length — expected \(expected) bytes, got \(actual)"
            case .invalidDate(let value):
                "Address book updatedAt is not a valid ISO-8601 date: \(value)"
            case .unparsableUpdatedAt(let value):
                "Address book response has an unparsable updatedAt: \(value)"
            }
        }
    }

    enum EnvelopeHexField: String {
        case walletId
        case nonce
        case ciphertext
        case authTag
    }

    private static let gcmNonceLength = 12
    private static let gcmTagLength = 16

    func mapToEnvelope(_ item: AddressBookDTO.Response.Item) throws -> RemoteAddressBook {
        let envelope = try makeEnvelope(
            version: item.version,
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

    func mapToSaveResult(_ response: AddressBookDTO.UpdateResponse) throws -> AddressBookSaveResult {
        guard let updatedAt = AddressBookBlobCodec.date(fromISO8601: response.updatedAt) else {
            throw MappingError.unparsableUpdatedAt(response.updatedAt)
        }

        return AddressBookSaveResult(etag: response.etag, updatedAt: updatedAt)
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

        let walletId = try data(fromHex: walletId, field: .walletId)
        let nonce = try data(fromHex: nonce, field: .nonce, expectedLength: Self.gcmNonceLength)
        let ciphertext = try data(fromHex: ciphertext, field: .ciphertext)
        let tag = try data(fromHex: authTag, field: .authTag, expectedLength: Self.gcmTagLength)

        return AddressBookEnvelope(
            version: version,
            walletId: UserWalletId(value: walletId),
            updatedAt: date,
            sealedBox: AddressBookSealedBox(nonce: nonce, ciphertext: ciphertext, tag: tag)
        )
    }

    private func data(fromHex hex: String, field: EnvelopeHexField) throws -> Data {
        let data = Data(hexString: hex)

        guard !data.isEmpty else {
            throw MappingError.invalidHex(field: field)
        }

        return data
    }

    private func data(fromHex hex: String, field: EnvelopeHexField, expectedLength: Int) throws -> Data {
        let data = try data(fromHex: hex, field: field)

        guard data.count == expectedLength else {
            throw MappingError.invalidLength(field: field, expected: expectedLength, actual: data.count)
        }

        return data
    }
}
