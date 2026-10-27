//
//  ResolvedSwapSourceTokenResolver.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import TangemFoundation

struct ResolvedSwapSourceTokenResolver {
    let token: SendSwapableToken
}

// MARK: - SwapSourceTokenResolver

extension ResolvedSwapSourceTokenResolver: SwapSourceTokenResolver {
    var initialSource: LoadingResult<SendSwapableToken, any Error> {
        .success(token)
    }

    func resolveSource(for receive: SendReceiveToken?) async throws -> SendSwapableToken {
        token
    }
}
