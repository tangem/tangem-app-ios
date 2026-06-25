//
//  CommonMobileWalletSdkSignTests.swift
//  TangemMobileWalletSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Testing
import Foundation
@testable import TangemMobileWalletSdk
@testable import TangemSdk

struct CommonMobileWalletSdkSignTests {
    /// Regression for [REDACTED_INFO]: a UTXO transaction spending several inputs from one address
    /// (i.e. several `SignData` sharing one public key) must keep each input's own signature.
    /// The signer used to key results by public key, so every input but the last lost its
    /// signature and WalletCore failed compilation with `errorSigning`.
    @Test
    func signKeepsPerInputSignaturesWhenInputsShareOnePublicKey() throws {
        let sdk = makeSdk()

        let walletId = try sdk.importWallet(entropy: entropy, passphrase: "")
        let context = try sdk.validate(auth: .none, for: walletId)

        let secp256k1Key = try #require(
            sdk.deriveMasterKeys(context: context).wallets.first { $0.curve == .secp256k1 }
        ).publicKey

        // Three inputs, three distinct hashes, all signed by the same public key.
        let hashes = [
            Data(hexString: String(repeating: "11", count: 32)),
            Data(hexString: String(repeating: "22", count: 32)),
            Data(hexString: String(repeating: "33", count: 32)),
        ]
        let dataToSign = hashes.map {
            SignData(derivationPath: nil, hashes: [$0], publicKey: secp256k1Key)
        }

        let result = try sdk.sign(dataToSign: dataToSign, seedKey: secp256k1Key, context: context)

        // One signature per input hash (here one hash per input), in order.
        #expect(result.count == hashes.count)

        // Each entry carries its own hash, public key, and the signature the crypto primitive produces for
        // that hash — proving inputs that share one public key keep their own signature instead of
        // collapsing onto the last one (the [REDACTED_INFO] regression).
        #expect(result.map(\.hash) == hashes)
        #expect(result.allSatisfy { $0.publicKey == secp256k1Key })

        let expectedSignatures = try hashes.flatMap {
            try SignUtil.sign(entropy: entropy, hashes: [$0], curve: .secp256k1, derivationPath: nil)
        }
        #expect(result.map(\.signature) == expectedSignatures)
    }
}

private extension CommonMobileWalletSdkSignTests {
    func makeSdk() -> CommonMobileWalletSdk {
        let secureStorage = MockedSecureStorage()
        let secureEnclaveService = MockedSecureEnclaveService()
        let biometricsSecureEnclaveService = MockedBiometricsSecureEnclaveService()
        let biometricsStorage = MockedBiometricsStorage()

        let encryptedSecureStorage = EncryptedSecureStorage(
            secureStorage: secureStorage,
            secureEnclaveService: secureEnclaveService
        )

        return CommonMobileWalletSdk(
            privateInfoStorageManager: PrivateInfoStorageManager(
                privateInfoStorage: PrivateInfoStorage(
                    secureStorage: secureStorage,
                    secureEnclaveService: secureEnclaveService
                ),
                encryptedSecureStorage: encryptedSecureStorage,
                encryptedBiometricsStorage: EncryptedBiometricsStorage(
                    biometricsStorage: biometricsStorage,
                    secureEnclaveBiometricsService: biometricsSecureEnclaveService
                )
            ),
            publicInfoStorageManager: PublicInfoStorageManager(
                encryptedSecureStorage: encryptedSecureStorage
            )
        )
    }
}
