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
        case invalidHex(field: String)
        case invalidDate(String)
    }

    private static let dateFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()

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
            updatedAt: Self.dateFormatter.string(from: envelope.updatedAt),
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
        guard let date = Self.dateFormatter.date(from: updatedAt) else {
            throw MappingError.invalidDate(updatedAt)
        }

        let sealedBox = try AddressBookSealedBox(
            nonce: data(fromHex: nonce, field: "nonce"),
            ciphertext: data(fromHex: ciphertext, field: "ciphertext"),
            tag: data(fromHex: authTag, field: "auth_tag")
        )

        return AddressBookEnvelope(
            version: version,
            walletId: UserWalletId(value: Data(hexString: walletId)),
            updatedAt: date,
            sealedBox: sealedBox
        )
    }

    private func data(fromHex hex: String, field: String) throws -> Data {
        let data = Data(hexString: hex)

        guard !data.isEmpty || hex.isEmpty else {
            throw MappingError.invalidHex(field: field)
        }

        return data
    }
}
