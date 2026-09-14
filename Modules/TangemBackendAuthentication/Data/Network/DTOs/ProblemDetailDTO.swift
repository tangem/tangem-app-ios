//
//  ProblemDetailDTO.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

/// The backend uses ProblemDetail class from Spring framework for different types of exceptions,
/// that may share the same status code. The only way to distinguish is to rely on exact detail string match.
enum ProblemDetailDTO {
    struct Response: Decodable, Equatable {
        let detail: String

        static let deviceNotFound = Response(detail: "Device not found")
        static let walletAlreadyRegistered = Response(detail: "Wallet is already registered for this device")
        static let walletNotRegistered = Response(detail: "Wallet is not registered for this device")
    }
}
