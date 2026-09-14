//
//  PolymarketL2Auth.swift
//  TangemPolymarket
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import CryptoSwift

public enum PolymarketL2AuthError: Error, Equatable {
    case invalidSecret
    case signingFailed
}

public enum PolymarketL2Auth {
    public static func headers(
        credentials: PolymarketL2Credentials,
        ownerAddress: String,
        timestamp: String,
        method: String,
        requestPath: String,
        body: String = ""
    ) throws(PolymarketL2AuthError) -> PolymarketL2AuthHeaders {
        let signature = try signature(
            secret: credentials.secret,
            timestamp: timestamp,
            method: method,
            requestPath: requestPath,
            body: body
        )

        return PolymarketL2AuthHeaders(
            ownerAddress: ownerAddress,
            signature: signature,
            timestamp: timestamp,
            apiKey: credentials.apiKey,
            passphrase: credentials.passphrase
        )
    }

    public static func signature(
        secret: String,
        timestamp: String,
        method: String,
        requestPath: String,
        body: String = ""
    ) throws(PolymarketL2AuthError) -> String {
        guard let key = base64URLDecoded(secret) else {
            throw .invalidSecret
        }

        let message = timestamp + method + requestPath + body

        do {
            let raw = try HMAC(key: key.bytes, variant: .sha2(.sha256)).authenticate(Array(message.utf8))
            return base64URLEncoded(Data(raw))
        } catch {
            throw .signingFailed
        }
    }
}

// MARK: - Private implementation

private extension PolymarketL2Auth {
    static func base64URLDecoded(_ value: String) -> Data? {
        var normalized = value
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")

        let remainder = normalized.count % 4

        if remainder > 0 {
            normalized += String(repeating: "=", count: 4 - remainder)
        }

        return Data(base64Encoded: normalized)
    }

    static func base64URLEncoded(_ data: Data) -> String {
        data.base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
    }
}
