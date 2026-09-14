//
//  CardUserWalletRegistrationSigner.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk
import TangemFoundation
import TangemBackendAuthentication

/// Stored properties are immutable, hence `@unchecked Sendable`.
final class CardUserWalletRegistrationSigner: @unchecked Sendable {
    private let session: CardSession
    private let walletPublicKey: Data

    init(session: CardSession, walletPublicKey: Data) {
        self.session = session
        self.walletPublicKey = walletPublicKey
    }

    deinit {
        BackendAuthLogger.debug(self, "deinit")
    }

    private func makeAttestation(
        from response: AttestWalletKeyResponse,
        decryptedNonceBytes: Data,
        cardPublicKey: Data,
        isWalletImported: Bool
    ) throws(UserWalletRegistrationSignerError) -> UserWalletAttestation {
        let walletSignature = try makeWalletSignature(from: response, decryptedNonceBytes: decryptedNonceBytes)

        guard
            let rawCardSignature = response.cardSignature,
            let cardSignatureSalt = response.publicKeySalt
        else {
            // Both signature and origin require >= COS 2.01
            return UserWalletAttestation(walletSignature: walletSignature, cardSignature: nil, origin: nil)
        }

        let walletStatusByte: Data
        let origin: UserWalletAttestation.Origin?

        // Status requires >= COS 6.16
        if let walletStatus = response.walletStatus {
            walletStatusByte = walletStatus.rawValue.byte
            origin = isWalletImported ? .seedImported : .generatedOnCard
        } else {
            walletStatusByte = Data()
            origin = nil
        }

        let cardSignature = try makeCardSignature(
            from: rawCardSignature,
            salt: cardSignatureSalt,
            walletStatusByte: walletStatusByte,
            decryptedNonceBytes: decryptedNonceBytes,
            cardPublicKey: cardPublicKey
        )

        return UserWalletAttestation(walletSignature: walletSignature, cardSignature: cardSignature, origin: origin)
    }

    private func makeWalletSignature(
        from response: AttestWalletKeyResponse,
        decryptedNonceBytes: Data
    ) throws(UserWalletRegistrationSignerError) -> UserWalletAttestation.Signature {
        do {
            let hash = (decryptedNonceBytes + response.salt).getSHA256()
            // r || s -> r || s || v, since the backend needs to recover the public key from the signature
            let recovered = try Secp256k1Signature(with: response.walletSignature).unmarshal(with: walletPublicKey, hash: hash)

            return .init(value: recovered.data, salt: response.salt)
        } catch {
            throw .signatureRecoveryFailed(underlying: error)
        }
    }

    private func makeCardSignature(
        from rawSignature: Data,
        salt: Data,
        walletStatusByte: Data,
        decryptedNonceBytes: Data,
        cardPublicKey: Data
    ) throws(UserWalletRegistrationSignerError) -> UserWalletAttestation.Signature {
        do {
            // The message is constructed in the same way as in the `AttestWalletKeyTask.verifyCardSignature`
            let message = walletPublicKey + decryptedNonceBytes + salt + walletStatusByte
            // r || s -> r || s || v, since the backend needs to recover the public key from the signature
            let recovered = try Secp256k1Signature(with: rawSignature).unmarshal(with: cardPublicKey, hash: message.getSHA256())

            return .init(value: recovered.data, salt: salt)
        } catch {
            throw .signatureRecoveryFailed(underlying: error)
        }
    }
}

// MARK: - UserWalletRegistrationSigner protocol conformance

extension CardUserWalletRegistrationSigner: UserWalletRegistrationSigner {
    func attest(decryptedNonceBytes: Data) async throws(UserWalletRegistrationSignerError) -> UserWalletAttestation {
        guard
            let card = session.environment.card,
            let wallet = card.wallets[walletPublicKey]
        else {
            throw .walletKeyUnavailable(underlying: "Missing card or wallet in session environment")
        }

        let response: AttestWalletKeyResponse

        do {
            response = try await AttestWalletKeyTask(
                walletPublicKey: walletPublicKey,
                challenge: decryptedNonceBytes
            ).run(in: session)
        } catch {
            throw .signingFailed(underlying: error)
        }

        return try makeAttestation(
            from: response,
            decryptedNonceBytes: decryptedNonceBytes,
            cardPublicKey: card.cardPublicKey,
            isWalletImported: wallet.isImported
        )
    }
}

// MARK: - CustomStringConvertible protocol conformance

extension CardUserWalletRegistrationSigner: CustomStringConvertible {
    var description: String {
        objectDescription(self, userInfo: [
            "walletPublicKey": walletPublicKey.hexString.masked(),
        ])
    }
}
