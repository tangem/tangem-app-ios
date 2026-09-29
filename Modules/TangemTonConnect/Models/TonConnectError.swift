//
//  TonConnectError.swift
//  TangemModules
//
//  Created by Dean Rie
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

/// Wallet-side failures of the TON Connect core. Every case maps to a protocol error code
/// (`TonConnectErrorCode`) so the caller can answer the dApp without inspecting the case.
public enum TonConnectError: Error, Equatable, Sendable {
    // Deep link
    case unsupportedProtocolVersion(String?)
    case invalidClientID
    case malformedConnectRequest(String)

    // Manifest
    case manifestNotFound
    case manifestContentError(String)

    // Session / envelope
    case cryptoFailure
    case decryptionFailed
    case malformedEnvelope(String)
    case requestIDNotIncreasing(received: String, last: String)
    case unknownSession

    // RPC
    case methodNotSupported(String)
    case badRequest(String)
    case userDeclined
    case internalFailure(String)

    /// Protocol error code the wallet should return to the dApp for this failure.
    public var protocolCode: TonConnectErrorCode {
        switch self {
        case .unsupportedProtocolVersion, .invalidClientID, .malformedConnectRequest, .malformedEnvelope, .badRequest, .requestIDNotIncreasing:
            return .badRequest
        case .manifestNotFound:
            return .manifestNotFound
        case .manifestContentError:
            return .manifestContentError
        case .unknownSession:
            return .unknownApp
        case .methodNotSupported:
            return .methodNotSupported
        case .userDeclined:
            return .userDeclined
        case .cryptoFailure, .decryptionFailed, .internalFailure:
            return .unknownError
        }
    }

    /// Short human-readable message for the `WalletResponseError.error.message` field.
    public var protocolMessage: String {
        switch self {
        case .unsupportedProtocolVersion(let version):
            return "Unsupported TON Connect protocol version: \(version ?? "missing")"
        case .invalidClientID:
            return "Invalid client id"
        case .malformedConnectRequest(let reason), .malformedEnvelope(let reason), .badRequest(let reason), .internalFailure(let reason):
            return reason
        case .manifestNotFound:
            return "App manifest not found"
        case .manifestContentError(let reason):
            return "App manifest content error: \(reason)"
        case .cryptoFailure:
            return "Cryptographic operation failed"
        case .decryptionFailed:
            return "Message could not be decrypted"
        case .requestIDNotIncreasing(let received, let last):
            return "Request id \(received) is not greater than the last processed id \(last)"
        case .unknownSession:
            return "Unknown app"
        case .methodNotSupported(let method):
            return "Method not supported: \(method)"
        case .userDeclined:
            return "User declined the request"
        }
    }
}

/// Error codes shared by connect events and RPC responses (`spec/connect.md`, `spec/rpc.md`).
public enum TonConnectErrorCode: Int, Codable, Sendable {
    case unknownError = 0
    case badRequest = 1
    case manifestNotFound = 2
    case manifestContentError = 3
    case unknownApp = 100
    case userDeclined = 300
    case methodNotSupported = 400
}
