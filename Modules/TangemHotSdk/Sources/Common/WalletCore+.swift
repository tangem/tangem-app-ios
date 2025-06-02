//
//  WalletCore+.swift
//  TangemHotSdk
//
//  Created by [REDACTED_AUTHOR]
//

import Foundation
import WalletCore
import TangemSdk
import TangemFoundation

extension WalletCore.Curve {
    init?(_ curve: EllipticCurve) {
        switch curve {
        case .secp256k1: self = .secp256k1
        case .ed25519_slip0010: self = .ed25519
        case .bip0340: self = .ed25519ExtendedCardano
        default: return nil
        }
    }
}

extension WalletCore.PrivateKey {
    func cardanoStakingKey() -> PrivateKey? {
        let stakingKeyBytes = Data(
            data.bytes[data.bytes.count / 2 ..< data.bytes.count]
        ).trailingZeroPadding(toLength: 192)

        let stakingPrivateKeyData = Data(stakingKeyBytes)
        return PrivateKey(data: stakingPrivateKeyData)
    }
}
