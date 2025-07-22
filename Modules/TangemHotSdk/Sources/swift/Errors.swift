//
//  File.swift
//  TangemHotSdk
//
//  Created by [REDACTED_AUTHOR]
//

import Foundation
import TangemSdk

enum HotWalletError: Error, Equatable {
    case derivationIsNotSupported
    case invalidStakingKey
    case invalidEntropySize
    case invalidCurve(_ curve: EllipticCurve)
    case failedToCreateMnemonic
    case failedToDeriveKey
    case failedToCreateSeed
    case failedToSignHash

    case tangemSdk(TangemSdkError)

    static func == (lhs: HotWalletError, rhs: HotWalletError) -> Bool {
        switch (lhs, rhs) {
        case (.derivationIsNotSupported, .derivationIsNotSupported),
             (.invalidStakingKey, .invalidStakingKey): true
        case (.tangemSdk(let left), .tangemSdk(let right)) where left.code == right.code: true
        default: false
        }
    }
}
