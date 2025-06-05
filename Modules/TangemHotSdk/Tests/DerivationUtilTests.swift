//
//  DerivationUtilTests.swift
//  TangemHotSdk
//
//  Created by [REDACTED_AUTHOR]
//

import Testing
@preconcurrency import WalletCore
@testable import TangemHotSdk
@testable @preconcurrency import TangemSdk
@testable import TangemFoundation

let entropy = Data(hexString: "E269A10D56F58A93611FB45EB11959C2")
let hdWallet = HDWallet(
    entropy: entropy,
    passphrase: ""
)!

struct DerivationUtilTests {
    @Test
    func secp256k1DerivationPaths() throws {
        let bitcoinResult = try DerivationUtil.deriveKeys(
            hdWallet: hdWallet,
            derivationPath: "m/84'/0'/0'/0/0",
            curve: .secp256k1
        )

        #expect(bitcoinResult.hexString == "02616104143281B4679AFEB669392B073D63564606F431D13DF3EBEDE75D269509")

        let ethereumResult = try DerivationUtil.deriveKeys(
            hdWallet: hdWallet,
            derivationPath: "m/44'/60'/0'/0/0",
            curve: .secp256k1
        )

        #expect(ethereumResult.hexString == "023A291DBF3427922A22D166C8D3333253A0E383115CF5DB36BE47EC5EA81D7D56")
    }

    @Test
    func edCardanoDerivationPath() throws {
        let result = try DerivationUtil.deriveKeys(
            hdWallet: hdWallet,
            derivationPath: "m/1852'/1815'/0'/0/0",
            curve: .ed25519
        )

        let expected = "C1C725C16E90BBC4B52C1EE1F91D33EE4FC2BD38878D50B5D427BB86300269A20304A5F27B4CF4C07C8E3FE723FB202067974BE46203F00C6AEAD95435619AA0EAEF8F031A8184CA52A3D2CB169D0395603B02DAD86FAD1E2315241CC5FB6A4923F204DAD0485EEEF85173DA7092ADC833E46F69C1CC075AAA0BB977322A5A57"

        #expect(result.hexString == expected)
    }

    @Test
    func edDerivationPath() throws {
        let result = try DerivationUtil.deriveKeys(
            hdWallet: hdWallet,
            derivationPath: "m/44'/354'/0'/0'/0'",
            curve: .ed25519_slip0010
        )

        let expected = "1A32F68FAABFFEAA618CD6B03D7CF0985E60688399A047166DE2F8686F074EBE"

        #expect(result.hexString == expected)
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
                hdWallet: hdWallet,
                derivationPath: "m/44'/0'/0'/0/0",
                curve: curve
            )
        }
    }

    @Test(
        arguments: [
            EllipticCurve.secp256k1,
            EllipticCurve.ed25519,
            EllipticCurve.ed25519_slip0010,
        ]
    )
    func emptyDerivationThrows(curve: EllipticCurve) throws {
        #expect(throws: Error.self) {
            try DerivationUtil.deriveKeys(
                hdWallet: hdWallet,
                derivationPath: "",
                curve: curve
            )
        }
    }
}
