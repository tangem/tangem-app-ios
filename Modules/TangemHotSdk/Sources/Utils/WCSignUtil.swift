//
//  SignUtil.swift
//  TangemHotSdk
//
//  Created by [REDACTED_AUTHOR]
//

import Foundation
import TangemSdk
import WalletCore

enum WCSignUtil {
    static func sign(
        hdWallet: HDWallet,
        hashes: [Data],
        curve: EllipticCurve,
        derivationPath: String
    ) throws -> [Data] {
        let derivationPath = try TangemSdkDerivationPath(rawPath: derivationPath)

        return try hashes.compactMap { hash -> Data? in
            switch curve {
            case .secp256k1:
                return try hdWallet
                    .getKeyByCurve(curve: .secp256k1, derivationPath: derivationPath.rawPath)
                    .sign(digest: hash, curve: .secp256k1)
                    .flatMap { try Secp256k1Signature(with: $0).normalize() }
            case .ed25519 where derivationPath.rawPath == Constants.cardanoStakingDerivationPath:
                let privateKey = hdWallet.getKey(
                    coin: .cardano,
                    derivationPath: Constants.cardanoDefaultDerivationPath
                )

                guard let stakingPrivateKey = privateKey.cardanoStakingKey() else {
                    throw HotWalletError.invalidStakingKey
                }

                return stakingPrivateKey.sign(digest: hash, curve: .ed25519ExtendedCardano)
            case .ed25519:
                return hdWallet.getKey(coin: .cardano, derivationPath: derivationPath.rawPath)
                    .sign(digest: hash, curve: .ed25519ExtendedCardano)
            case .ed25519_slip0010:
                return hdWallet
                    .getKeyByCurve(curve: .ed25519, derivationPath: derivationPath.rawPath)
                    .sign(digest: hash, curve: .ed25519)
            default:
                throw HotWalletError.tangemSdk(.unsupportedCurve)
            }
        }
    }
}

extension WCSignUtil {
    enum Constants {
        static let cardanoDefaultDerivationPath = "m/1852'/1815'/0'/0/0"
        static let cardanoStakingDerivationPath = "m/1852'/1815'/0'/2/0"
    }
}
