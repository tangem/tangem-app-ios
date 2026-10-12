//
//  Analytics+OtelParamOverrides.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

extension Analytics {
    /// A custom token's symbol is whatever the user typed in, so the OTel attribute gets a bounded
    /// stand-in instead of growing a series per symbol. The analytics services keep the real symbol.
    static func otelCustomTokenOverrides(
        token: TokenItem? = nil,
        feeToken: TokenItem? = nil,
        sendToken: TokenItem? = nil
    ) -> [ParameterKey: String] {
        let candidates: [(key: ParameterKey, tokenItem: TokenItem?)] = [
            (.token, token),
            (.feeToken, feeToken),
            (.sendToken, sendToken),
        ]

        return candidates.reduce(into: [:]) { overrides, candidate in
            guard candidate.tokenItem?.token?.isCustom == true else { return }

            overrides[candidate.key] = ParameterValue.custom.rawValue
        }
    }
}
