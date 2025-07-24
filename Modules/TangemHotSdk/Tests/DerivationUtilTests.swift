//
//  DerivationUtilTests.swift
//  TangemHotSdk
//
//  Created by [REDACTED_AUTHOR]
//

import Testing
import Foundation
@testable import TangemHotSdk
@testable @preconcurrency import TangemSdk
@testable import TangemFoundation

let entropy = Data(hexString: "E269A10D56F58A93611FB45EB11959C2")

struct DerivationUtilTests {
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
            derivationPath: try DerivationPath(rawPath:  "m/44'/60'/0'/0/0"),
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

        let expected = "C1C725C16E90BBC4B52C1EE1F91D33EE4FC2BD38878D50B5D427BB86300269A20304A5F27B4CF4C07C8E3FE723FB202067974BE46203F00C6AEAD95435619AA0EAEF8F031A8184CA52A3D2CB169D0395603B02DAD86FAD1E2315241CC5FB6A4923F204DAD0485EEEF85173DA7092ADC833E46F69C1CC075AAA0BB977322A5A57"

        #expect(result.publicKey.hexString == expected)
    }

    @Test
    func edCardanoDeriveFromMasterKey() throws {
        let result = try DerivationUtil.deriveKeys(
            entropy: entropy,
            derivationPath: try DerivationPath(rawPath: "m/1852'/1815'/0'/0/0"),
            masterKey: Data(hexString: "32ea4ee339b0b01233e5f0728d733dc68a26d17a58c140aa23fe1c8eeabd5abe"),
        )

        let expected = "C1C725C16E90BBC4B52C1EE1F91D33EE4FC2BD38878D50B5D427BB86300269A20304A5F27B4CF4C07C8E3FE723FB202067974BE46203F00C6AEAD95435619AA0EAEF8F031A8184CA52A3D2CB169D0395603B02DAD86FAD1E2315241CC5FB6A4923F204DAD0485EEEF85173DA7092ADC833E46F69C1CC075AAA0BB977322A5A57"

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
        #expect(throws: HotWalletError.self) {
            try DerivationUtil.deriveKeys(
                entropy: entropy,
                derivationPath: try DerivationPath(rawPath: "m/44'/0'/0'/0/0"),
                curve: curve
            )
        }
    }
}
