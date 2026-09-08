//
//  NonceResponseFixture.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

enum NonceResponseFixture {
    static func valid(cipheredNonce: String) -> String {
        #"{"cipheredNonce":"\#(cipheredNonce)","expiresAt":"2026-01-01T00:00:00Z"}"#
    }

    static let invalid = #"{"beep-bop":67}"#
}
