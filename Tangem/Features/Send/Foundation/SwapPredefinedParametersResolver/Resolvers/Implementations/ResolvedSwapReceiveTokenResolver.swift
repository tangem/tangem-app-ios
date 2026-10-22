//
//  ResolvedSwapReceiveTokenResolver.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import TangemFoundation

struct ResolvedSwapReceiveTokenResolver {
    let token: SendReceiveToken
}

// MARK: - SwapReceiveTokenResolver

extension ResolvedSwapReceiveTokenResolver: SwapReceiveTokenResolver {
    var initialReceive: LoadingResult<SendReceiveToken, any Error> {
        .success(token)
    }

    func resolveReceive(for source: SendSwapableToken?) async throws -> SendReceiveToken {
        token
    }
}
