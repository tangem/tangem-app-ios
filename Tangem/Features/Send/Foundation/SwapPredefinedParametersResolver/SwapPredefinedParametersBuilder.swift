//
//  SwapPredefinedParametersBuilder.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

struct SwapPredefinedParametersBuilder {
    func makeParameters(input: Input) -> PredefinedSwapParameters {
        switch input {
        case .main(let userWalletModel):
            makeMainParameters(userWalletModel: userWalletModel)
        case .token(let userWalletInfo, let walletModel, let direction):
            makeTokenParameters(walletModel: walletModel, userWalletInfo: userWalletInfo, direction: direction)
        case .pair(let userWalletInfo, let source, let receive, let extras):
            makePairParameters(source: source, receive: receive, userWalletInfo: userWalletInfo, extras: extras)
        }
    }
}

// MARK: - Input

extension SwapPredefinedParametersBuilder {
    enum Input {
        case main(userWalletModel: any UserWalletModel)
        case token(userWalletInfo: UserWalletInfo, walletModel: any WalletModel, direction: SwapDirection)
        case pair(
            userWalletInfo: UserWalletInfo,
            source: any WalletModel,
            receive: (any WalletModel)?,
            extras: PredefinedSwapParameters.Extras?
        )
    }
}

// MARK: - Private

private extension SwapPredefinedParametersBuilder {
    func makeMainParameters(userWalletModel: any UserWalletModel) -> PredefinedSwapParameters {
        let userWalletInfo = userWalletModel.userWalletInfo

        return PredefinedSwapParameters(
            userWalletInfo: userWalletInfo,
            source: MainSwapSourceResolver(
                userWalletModel: userWalletModel,
                swapAvailabilityChecker: CommonSwapAvailabilityChecker(userWalletInfo: userWalletInfo)
            ),
            receive: .userSelection
        )
    }

    func makeTokenParameters(
        walletModel: any WalletModel,
        userWalletInfo: UserWalletInfo,
        direction: SwapDirection
    ) -> PredefinedSwapParameters {
        switch direction {
        case .from:
            let token = makeSwapableToken(walletModel: walletModel, userWalletInfo: userWalletInfo)
            return PredefinedSwapParameters(
                userWalletInfo: userWalletInfo,
                source: .resolved(token),
                receive: .userSelection
            )
        case .to:
            let receiveToken = makeReceiveToken(walletModel: walletModel, userWalletInfo: userWalletInfo)
            let sourceResolver = TokenDetailsSwapSourceResolver(
                swapAvailabilityChecker: CommonSwapAvailabilityChecker(userWalletInfo: userWalletInfo)
            )

            let sourceWalletModel = sourceResolver.resolveSource(for: walletModel)
            let source: any SwapSourceTokenResolver = if let sourceWalletModel {
                .resolved(makeSwapableToken(walletModel: sourceWalletModel, userWalletInfo: userWalletInfo))
            } else {
                .userSelection
            }

            return PredefinedSwapParameters(
                userWalletInfo: userWalletInfo,
                source: source,
                receive: .resolved(receiveToken)
            )
        }
    }

    func makePairParameters(
        source: any WalletModel,
        receive: (any WalletModel)?,
        userWalletInfo: UserWalletInfo,
        extras: PredefinedSwapParameters.Extras?
    ) -> PredefinedSwapParameters {
        let sourceToken = makeSwapableToken(walletModel: source, userWalletInfo: userWalletInfo)
        let receiveResolver: any SwapReceiveTokenResolver = if let receive {
            .resolved(makeReceiveToken(walletModel: receive, userWalletInfo: userWalletInfo))
        } else {
            .userSelection
        }

        return PredefinedSwapParameters(
            userWalletInfo: userWalletInfo,
            source: .resolved(sourceToken),
            receive: receiveResolver,
            extras: extras
        )
    }

    func makeReceiveToken(walletModel: any WalletModel, userWalletInfo: UserWalletInfo) -> SendSourceToken {
        if walletModel.isJointAccountParticipant {
            return CommonSendSourceTokenFactory(userWalletInfo: userWalletInfo, walletModel: walletModel).makeSourceToken()
        }

        return makeSwapableToken(walletModel: walletModel, userWalletInfo: userWalletInfo)
    }

    func makeSwapableToken(walletModel: any WalletModel, userWalletInfo: UserWalletInfo) -> SendSwapableToken {
        CommonSendSwapableTokenFactory(
            userWalletInfo: userWalletInfo,
            walletModel: walletModel,
            operationType: .swap
        ).makeSwapableToken()
    }
}
