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
    case failedToExportMnemonic
    case encryptionKeyIsNotAvailableViaBiometrics

    case tangemSdk(TangemSdkError)

    static func == (lhs: HotWalletError, rhs: HotWalletError) -> Bool {
        switch (lhs, rhs) {
        case (.derivationIsNotSupported, .derivationIsNotSupported),
             (.invalidStakingKey, .invalidStakingKey),
             (.failedToCreateMnemonic, .failedToCreateMnemonic),
             (.failedToDeriveKey, .failedToDeriveKey),
             (.failedToCreateSeed, .failedToCreateSeed),
             (.failedToSignHash, .failedToSignHash),
             (.encryptionKeyIsNotAvailableViaBiometrics, .encryptionKeyIsNotAvailableViaBiometrics),
             (.failedToExportMnemonic, .failedToExportMnemonic): true
        case (.invalidCurve(let left), .invalidCurve(let right)) where left == right: true
        case (.tangemSdk(let left), .tangemSdk(let right)) where left.code == right.code: true
        default: false
        }
    }
}
