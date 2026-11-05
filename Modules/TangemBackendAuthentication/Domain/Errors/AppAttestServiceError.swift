//
//  AppAttestServiceError.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

public enum AppAttestServiceError: Error {
    case deviceCheckUnsupported

    case keyGenerationFailed(underlying: any Error)
    case keychainFailure(KeychainRepositoryError)

    case attestationServerUnavailable
    case attestationFailed(underlying: any Error)

    case assertionKeyCorrupted
    case assertionKeyNotFound

    case assertionFailed(underlying: any Error)
}
