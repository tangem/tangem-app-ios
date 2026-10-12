//
//  DPoPHeadersFactory.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

enum DPoPHeadersFactory {
    static func make(accessToken: String, dPoPProof: String) -> [String: String] {
        [
            "Authorization": "DPoP \(accessToken)",
            "DPoP": dPoPProof,
        ]
    }
}
