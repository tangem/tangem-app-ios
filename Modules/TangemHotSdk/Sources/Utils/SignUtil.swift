//
//  SignUtil.swift
//  TangemHotSdk
//
//  Created by [REDACTED_AUTHOR]
//

import Foundation
import TangemSdk

enum SignUtil {
    static func sign(
        entropy: Data,
        passphrase: String? = nil,
        hashes: [Data],
        curve: EllipticCurve,
        derivationPath: String
    ) throws -> [Data] {
        let derivationPath = try DerivationPath(rawPath: derivationPath)

        return try hashes.compactMap { hash -> Data? in
            switch curve {
            case .secp256k1:
                fatalError("Implement for secp, don't forget Secp256k1Signature(with: $0).normalize()")
            case .ed25519:
                fatalError("Implement for ed, don't forget logic for staking if necessary")
            case .ed25519_slip0010:
                fatalError("Implement for ed_slip, don't forget logic for staking if necessary")
            default:
                throw HotWalletError.tangemSdk(.unsupportedCurve)
            }
        }
    }
}

extension SignUtil {
    enum Constants {
        static let cardanoDefaultDerivationPath = "m/1852'/1815'/0'/0/0"
        static let cardanoStakingDerivationPath = "m/1852'/1815'/0'/2/0"
    }
}
