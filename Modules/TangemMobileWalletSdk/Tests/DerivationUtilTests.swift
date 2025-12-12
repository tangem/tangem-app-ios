//
//  DerivationUtilTests.swift
//  TangemMobileWalletSdk
//
//  Created by [REDACTED_AUTHOR]
//

import Testing
import Foundation
@testable import TangemMobileWalletSdk
@testable @preconcurrency import TangemSdk
@testable import TangemFoundation

let entropy = Data(hexString: "E269A10D56F58A93611FB45EB11959C2")

struct DerivationUtilTests {
    @Test(
        arguments: [
            EllipticCurve.secp256k1,
            EllipticCurve.ed25519_slip0010,
        ]
    )
    func compareMasterKeysWithTangemSDK(curve: EllipticCurve) throws {
        let pubKeyFromMobileWallet = try DerivationUtil.deriveKeys(
            entropy: entropy,
            derivationPath: nil,
            curve: curve
        )

        let mnemonic = try Mnemonic(entropyData: entropy)
        let pubKeyFromMobileWalletTangemSdk = try AnyMasterKeyFactory(mnemonic: mnemonic, passphrase: "").makeMasterKey(for: curve).makePublicKey(for: curve)

        #expect(pubKeyFromMobileWallet.publicKey == pubKeyFromMobileWalletTangemSdk.publicKey)
        #expect(pubKeyFromMobileWallet.chainCode == pubKeyFromMobileWalletTangemSdk.chainCode)
    }

    @Test(
        arguments: [
            EllipticCurve.secp256k1,
            EllipticCurve.ed25519_slip0010,
        ]
    )
    func compareMasterKeysWithTangemSDKWithPassphrase(curve: EllipticCurve) throws {
        let passphrase = "test-passphrase"
        let pubKeyFromMobileWallet = try DerivationUtil.deriveKeys(
            entropy: entropy,
            passphrase: passphrase,
            derivationPath: nil,
            curve: curve
        )

        let mnemonic = try Mnemonic(entropyData: entropy)
        let pubKeyFromMobileWalletTangemSdk = try AnyMasterKeyFactory(mnemonic: mnemonic, passphrase: passphrase).makeMasterKey(for: curve).makePublicKey(for: curve)

        #expect(pubKeyFromMobileWallet.publicKey == pubKeyFromMobileWalletTangemSdk.publicKey)
        #expect(pubKeyFromMobileWallet.chainCode == pubKeyFromMobileWalletTangemSdk.chainCode)
    }

    @Test
    func compareMasterKeysWithTangemSDKStatic() throws {
        // ed25519
        let ed25519Key = try DerivationUtil.deriveKeys(
            entropy: entropy,
            derivationPath: nil,
            curve: .ed25519
        )

        #expect(ed25519Key.publicKey == Data(hexString: "32EA4EE339B0B01233E5F0728D733DC68A26D17A58C140AA23FE1C8EEABD5ABE"))
        #expect(ed25519Key.chainCode == Data(hexString: "055D207E832382121B9FF6C339628368131F90F9A50A3E36FFBBCBA804FBC4DC"))

        // bls12381_G2_AUG
        let blsKey = try BLSUtil.publicKey(entropy: entropy)
        #expect(blsKey.publicKey == Data(hexString: "B9247498D0F9EC5064185D717AF600E9F1788579D308471DF5AB76B9913E6E3E47F3363B8F424045DBA67630C4CA5222"))
    }

    @Test
    func compareMasterKeysWithTangemSDKStaticWithPassphrase() throws {
        let passphrase = "test-passphrase"

        // ed25519 with passphrase
        let ed25519Key = try DerivationUtil.deriveKeys(
            entropy: entropy,
            passphrase: passphrase,
            derivationPath: nil,
            curve: .ed25519
        )

        #expect(ed25519Key.publicKey == Data(hexString: "E0A38396F60683552BD6F85549480B74F4CC760579585F71015EDEC0ADF73139"))
        #expect(ed25519Key.chainCode == Data(hexString: "D6E974739B3864882EAF0B2541B6F94E72747BFCADE6A9EBA0E2F426C45DAA7D"))

        // bls12381_G2_AUG with passphrase
        let blsKey = try BLSUtil.publicKey(
            entropy: entropy,
            passphrase: passphrase
        )

        #expect(blsKey.publicKey == Data(hexString: "837119FBBF7759BAB615E5A6F89399B084E6001D07E351D35359C873B13A216EB1DD046B4F9FD784DE6DBBA39C83919A"))
    }

    @Test
    func secp256k1DerivationPaths() throws {
        let bitcoinResult = try DerivationUtil.deriveKeys(
            entropy: entropy,
            derivationPath: try DerivationPath(rawPath: "m/84'/0'/0'/0/0"),
            curve: .secp256k1
        )

        #expect(bitcoinResult.publicKey.hexString == "02616104143281B4679AFEB669392B073D63564606F431D13DF3EBEDE75D269509")
        #expect(bitcoinResult.chainCode.hexString == "EE4696FCB6920DBCBCF33423885C53CB5A16B5AD124715A26DF43299A087FB7D")

        let ethereumResult = try DerivationUtil.deriveKeys(
            entropy: entropy,
            derivationPath: try DerivationPath(rawPath: "m/44'/60'/0'/0/0"),
            curve: .secp256k1
        )

        #expect(ethereumResult.publicKey.hexString == "023A291DBF3427922A22D166C8D3333253A0E383115CF5DB36BE47EC5EA81D7D56")
        #expect(ethereumResult.chainCode.hexString == "01A5E27742465E0C7D2A7E3F7485717950095B1761DF8AD96944EED0140022E4")
    }

    @Test
    func secp256k1DeriveFromMasterKey() throws {
        let bitcoinResult = try DerivationUtil.deriveKeys(
            entropy: entropy,
            derivationPath: try DerivationPath(rawPath: "m/84'/0'/0'/0/0"),
            masterKey: Data(hexString: "0374D0F81F42DDFE34114D533E95E6AE5FE6EA271C96F1FA505199FDC365AE9720"),
        )

        #expect(bitcoinResult.publicKey.hexString == "02616104143281B4679AFEB669392B073D63564606F431D13DF3EBEDE75D269509")
        #expect(bitcoinResult.chainCode.hexString == "EE4696FCB6920DBCBCF33423885C53CB5A16B5AD124715A26DF43299A087FB7D")
    }

    @Test
    func secp256k1MasterKey() throws {
        let result = try DerivationUtil.deriveKeys(
            entropy: entropy,
            derivationPath: nil,
            curve: .secp256k1
        )

        #expect(result.publicKey.hexString == "0374D0F81F42DDFE34114D533E95E6AE5FE6EA271C96F1FA505199FDC365AE9720")
    }

    @Test
    func edCardanoDerivationPath() throws {
        let result = try DerivationUtil.deriveKeys(
            entropy: entropy,
            derivationPath: try DerivationPath(rawPath: "m/1852'/1815'/0'/0/0"),
            curve: .ed25519
        )

        let expected = "C1C725C16E90BBC4B52C1EE1F91D33EE4FC2BD38878D50B5D427BB86300269A2"
        #expect(result.publicKey.hexString == expected)
    }

    @Test
    func edCardanoDeriveFromMasterKey() throws {
        let result = try DerivationUtil.deriveKeys(
            entropy: entropy,
            derivationPath: try DerivationPath(rawPath: "m/1852'/1815'/0'/0/0"),
            masterKey: Data(hexString: "32ea4ee339b0b01233e5f0728d733dc68a26d17a58c140aa23fe1c8eeabd5abe"),
        )

        let expected = "C1C725C16E90BBC4B52C1EE1F91D33EE4FC2BD38878D50B5D427BB86300269A2"
        #expect(result.publicKey.hexString == expected)
    }

    @Test
    func edCardanoMasterKey() throws {
        let result = try DerivationUtil.deriveKeys(
            entropy: entropy,
            derivationPath: nil,
            curve: .ed25519
        )

        #expect(result.publicKey.hexString == "32ea4ee339b0b01233e5f0728d733dc68a26d17a58c140aa23fe1c8eeabd5abe".uppercased())
    }

    @Test
    func edDerivationPath() throws {
        let result = try DerivationUtil.deriveKeys(
            entropy: entropy,
            derivationPath: try DerivationPath(rawPath: "m/44'/354'/0'/0'/0'"),
            curve: .ed25519_slip0010
        )

        let expected = "1A32F68FAABFFEAA618CD6B03D7CF0985E60688399A047166DE2F8686F074EBE"

        #expect(result.publicKey.hexString == expected)
    }

    @Test
    func edNonHardenedDerivationPath() throws {
        #expect(throws: MobileWalletError.failedToDeriveKey) {
            try DerivationUtil.deriveKeys(
                entropy: entropy,
                derivationPath: try DerivationPath(rawPath: "m/44'/354'/0'/0'/0"),
                curve: .ed25519_slip0010
            )
        }
    }

    @Test
    func edDeriveFromMasterKey() throws {
        let result = try DerivationUtil.deriveKeys(
            entropy: entropy,
            derivationPath: try DerivationPath(rawPath: "m/44'/354'/0'/0'/0'"),
            masterKey: Data(hexString: "aac36941b9d4deb53d6c4a8cbadf0c25a509e39c83a7513c85ddf53b37ab4d51"),
        )

        let expected = "1A32F68FAABFFEAA618CD6B03D7CF0985E60688399A047166DE2F8686F074EBE"

        #expect(result.publicKey.hexString == expected)
    }

    @Test
    func edMasterKey() throws {
        let result = try DerivationUtil.deriveKeys(
            entropy: entropy,
            derivationPath: nil,
            curve: .ed25519_slip0010
        )

        #expect(result.publicKey.hexString == "aac36941b9d4deb53d6c4a8cbadf0c25a509e39c83a7513c85ddf53b37ab4d51".uppercased())
    }

    @Test(
        arguments: [
            EllipticCurve.bip0340,
            EllipticCurve.bls12381_G2,
            EllipticCurve.bls12381_G2_AUG,
            EllipticCurve.bls12381_G2_POP,
            EllipticCurve.secp256r1,
        ]
    )
    func unsupportedCurveThrows(curve: EllipticCurve) throws {
        #expect(throws: MobileWalletError.self) {
            try DerivationUtil.deriveKeys(
                entropy: entropy,
                derivationPath: try DerivationPath(rawPath: "m/44'/0'/0'/0/0"),
                curve: curve
            )
        }
    }
}
