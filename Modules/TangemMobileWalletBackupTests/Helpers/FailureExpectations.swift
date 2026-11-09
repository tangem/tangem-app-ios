//
//  FailureExpectations.swift
//  TangemMobileWalletBackupTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Testing
@testable import TangemMobileWalletBackup

@concurrent
func expectFailure<E: Error, T>(
    _ errorType: E.Type,
    matching predicate: (E) -> Bool,
    sourceLocation: SourceLocation = #_sourceLocation,
    _ operation: @concurrent () async throws -> T
) async {
    do {
        _ = try await operation()
        Issue.record("Expected \(errorType), but the operation succeeded", sourceLocation: sourceLocation)
    } catch let error as E where predicate(error) {
        return
    } catch {
        Issue.record("Expected \(errorType), got \(error)", sourceLocation: sourceLocation)
    }
}

@concurrent
func expectStorageUnavailable<T>(
    sourceLocation: SourceLocation = #_sourceLocation,
    _ operation: @concurrent () async throws -> T
) async {
    await expectFailure(WalletBackupStorageError.self, matching: \.isStorageUnavailable, sourceLocation: sourceLocation, operation)
}

@concurrent
func expectFileNotFound<T>(
    sourceLocation: SourceLocation = #_sourceLocation,
    _ operation: @concurrent () async throws -> T
) async {
    await expectFailure(WalletBackupStorageError.self, matching: \.isFileNotFound, sourceLocation: sourceLocation, operation)
}

// MARK: - Error matching

extension WalletBackupStorageError {
    var isStorageUnavailable: Bool {
        if case .storageUnavailable = self { true } else { false }
    }

    var isFileNotFound: Bool {
        if case .fileNotFound = self { true } else { false }
    }

    var isWalletMismatch: Bool {
        if case .walletMismatch = self { true } else { false }
    }
}

extension WalletBackupDecodingError {
    var isUnsupportedVersion: Bool {
        if case .unsupportedVersion = self { true } else { false }
    }

    var isDecodingFailed: Bool {
        if case .decodingFailed = self { true } else { false }
    }
}

extension WalletBackupCryptoError {
    var isInvalidKeyLength: Bool {
        if case .invalidKeyLength = self { true } else { false }
    }

    var isInvalidRecoveryKey: Bool {
        if case .invalidRecoveryKey = self { true } else { false }
    }
}
