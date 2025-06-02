//
//  DerivationUtil.swift
//  TangemHotSdk
//
//  Created by [REDACTED_AUTHOR]
//

import Foundation
import TangemSdk
import WalletCore

enum DerivationUtil {
    static func deriveKeys(
        hdWallet: HDWallet,
        derivationPath: String,
        curve: EllipticCurve
    ) throws -> Data {
        let derivationPath = try TangemSdkDerivationPath(rawPath: derivationPath)

        return switch curve {
        case .secp256k1:
            hdWallet
                .getKeyByCurve(curve: .secp256k1, derivationPath: derivationPath.rawPath)
                .getPublicKeySecp256k1(compressed: true).data // tangem card always produce compressed key
        case .ed25519:
            hdWallet
                .getKeyByCurve(curve: .ed25519ExtendedCardano, derivationPath: derivationPath.rawPath)
                .getPublicKeyEd25519Cardano().data
        case .ed25519_slip0010:
            hdWallet
                .getKeyByCurve(curve: .ed25519, derivationPath: derivationPath.rawPath)
                .getPublicKeyEd25519().data
        case .bls12381_G2_AUG:
            throw HotWalletError.derivationIsNotSupported
        default:
            throw HotWalletError.tangemSdk(.unsupportedCurve)
        }
    }
}
