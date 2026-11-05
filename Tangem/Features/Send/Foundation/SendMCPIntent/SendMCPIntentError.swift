//
//  SendMCPIntentError.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

enum SendMCPIntentError: Error {
    case invalidIntentId(String)
    case unsupportedType(String)
    case invalidAmount(String)
    case timeout
    case noInternetConnection
    case requestFailed(underlying: any Error)
}
