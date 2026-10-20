//
//  UserSelectionSwapTokenResolver.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import TangemFoundation

struct UserSelectionSwapTokenResolver {}

// MARK: - SwapSourceTokenResolver

extension UserSelectionSwapTokenResolver: SwapSourceTokenResolver {
    var initialSource: LoadingResult<SendSwapableToken, any Error> {
        .failure(SwapModel.SwapModelError.tokenSelectionRequired)
    }

    func resolveSource(for receive: SendReceiveToken?) async throws -> SendSwapableToken {
        throw SwapModel.SwapModelError.tokenSelectionRequired
    }
}

// MARK: - SwapReceiveTokenResolver

extension UserSelectionSwapTokenResolver: SwapReceiveTokenResolver {
    var initialReceive: LoadingResult<SendReceiveToken, any Error> {
        .failure(SwapModel.SwapModelError.tokenSelectionRequired)
    }

    func resolveReceive(for source: SendSwapableToken?) async throws -> SendReceiveToken {
        throw SwapModel.SwapModelError.tokenSelectionRequired
    }
}
