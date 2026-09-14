//
//  MobileUserWalletRegistrationSigner.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import struct CryptoKit.SHA256
import struct Foundation.Data
import TangemBackendAuthentication
import TangemMobileWalletSdk
import TangemSdk

struct MobileUserWalletRegistrationSigner: UserWalletRegistrationSigner {
    private nonisolated(unsafe) let context: MobileWalletContext
    private let secp256k1PublicKey: Data?
    private nonisolated(unsafe) let mobileWalletSDK: any MobileWalletSdk

    init(context: MobileWalletContext, secp256k1PublicKey: Data?, mobileWalletSDK: some MobileWalletSdk) {
        self.context = context
        self.secp256k1PublicKey = secp256k1PublicKey
        self.mobileWalletSDK = mobileWalletSDK
    }

    func attest(decryptedNonceBytes: Data) async throws(UserWalletRegistrationSignerError) -> UserWalletAttestation {
        let secp256k1PublicKey: Data

        if let existingKey = self.secp256k1PublicKey {
            secp256k1PublicKey = existingKey
        } else {
            secp256k1PublicKey = try deriveSecp256k1PublicKey(context: context)
        }

        let salt: Data

        do {
            salt = try CryptoUtils.generateRandomBytes(count: Constants.saltLength)
        } catch {
            throw UserWalletRegistrationSignerError.signingFailed(underlying: error)
        }

        let hash = Data(SHA256.hash(data: decryptedNonceBytes + salt))
        let signData = SignData(derivationPath: nil, hashes: [hash], publicKey: secp256k1PublicKey)

        let mobileWalletSignatures: [MobileWalletSignature]

        do {
            mobileWalletSignatures = try mobileWalletSDK.sign(
                dataToSign: [signData],
                seedKey: secp256k1PublicKey,
                context: context
            )
        } catch {
            throw UserWalletRegistrationSignerError.signingFailed(underlying: error)
        }

        // [REDACTED_TODO_COMMENT]
        guard let mobileWalletSignature = mobileWalletSignatures.first else {
            throw UserWalletRegistrationSignerError.signatureMissing
        }

        let rsvSignatureBytes: Data

        do {
            let signature = try Secp256k1Signature(with: mobileWalletSignature.signature)
            rsvSignatureBytes = try signature.unmarshal(with: secp256k1PublicKey, hash: hash).data
        } catch {
            throw UserWalletRegistrationSignerError.signatureRecoveryFailed(underlying: error)
        }

        return UserWalletAttestation(
            walletSignature: UserWalletAttestation.Signature(value: rsvSignatureBytes, salt: salt),
            cardSignature: nil,
            origin: nil
        )
    }

    private func deriveSecp256k1PublicKey(context: MobileWalletContext) throws(UserWalletRegistrationSignerError) -> Data {
        let mobileWallet: MobileWallet

        do {
            mobileWallet = try mobileWalletSDK.deriveMasterKeys(context: context)
        } catch {
            throw UserWalletRegistrationSignerError.keyDerivationFailed(underlying: error)
        }

        do {
            return try UserWalletRegistrationKeyUtils.walletPublicKeyToRegister(in: mobileWallet.wallets)
        } catch {
            throw UserWalletRegistrationSignerError.walletKeyUnavailable(underlying: error)
        }
    }
}

private extension MobileUserWalletRegistrationSigner {
    enum Constants {
        static let saltLength = 16
    }
}
