//
//  MainSwapSourceResolver.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

// MARK: - Main Resolver

final class MainSwapSourceResolver {
    private let userWalletInfo: UserWalletInfo
    private let walletModelsProvider: MainScreenUIOrderedWalletModelsProvider

    init(userWalletModel: UserWalletModel) {
        userWalletInfo = userWalletModel.userWalletInfo
        walletModelsProvider = MainScreenUIOrderedWalletModelsProvider(userWalletModel: userWalletModel)
    }
}

// MARK: - SwapSourceTokenResolver

extension MainSwapSourceResolver: SwapSourceTokenResolver {
    var initialSource: LoadingResult<SendSwapableToken, any Error> { .loading }

    func resolveSource(for receive: SendReceiveToken?) async throws -> SendSwapableToken {
        let walletModels = await walletModelsProvider.settledWalletModels()

        guard let source = resolveSourceToken(from: walletModels) else {
            throw SwapModel.SwapModelError.tokenSelectionRequired
        }

        return source
    }
}

// MARK: - Private

private extension MainSwapSourceResolver {
    func resolveSourceToken(from walletModels: [any WalletModel]) -> SendSwapableToken? {
        let candidates = walletModels.filter {
            TokenActionAvailabilityProvider(userWalletInfo: userWalletInfo, walletModel: $0).isSwapAvailable(direction: .from)
        }

        guard let source = candidates.mostFiatFundedOrFirst else {
            return nil
        }

        return CommonSendSwapableTokenFactory(
            userWalletInfo: userWalletInfo,
            walletModel: source,
            operationType: .swap
        ).makeSwapableToken()
    }
}
