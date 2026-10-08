//
//  WalletBackupPayloadDTO.swift
//  TangemMobileWalletBackup
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

/// Canonical plaintext schema sealed inside backup files.
struct WalletBackupPayloadDTO: Codable {
    let mnemonic: String
    let passphraseRequired: PassphraseRequirement

    enum PassphraseRequirement: Int, Codable {
        case notRequired = 0
        case required = 1
    }
}

// MARK: - Payload serialization

extension WalletBackupPayloadDTO {
    static func encode(_ payload: any WalletBackupPayload) throws -> Data {
        let mnemonic = payload.mnemonicWords.joined(separator: " ")
        let passphraseRequired = payload.requiresPassphrase ? PassphraseRequirement.required : .notRequired
        let dto = WalletBackupPayloadDTO(mnemonic: mnemonic, passphraseRequired: passphraseRequired)

        do {
            return try WalletBackupJSONCodec.encode(dto)
        } catch {
            throw WalletBackupEncodingError.payloadEncodingFailed
        }
    }

    static func decode(_ payloadData: Data) throws -> CommonWalletBackupPayload {
        do {
            let dto = try WalletBackupJSONCodec.decode(WalletBackupPayloadDTO.self, from: payloadData)
            return CommonWalletBackupPayload(
                mnemonicWords: dto.mnemonic.split(separator: " ").map(String.init),
                requiresPassphrase: dto.passphraseRequired == .required
            )
        } catch {
            throw WalletBackupDecodingError.payloadDecodingFailed
        }
    }
}
