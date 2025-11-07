//
//  SendReceiveTokensListBuilder.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import TangemExpress

struct SendReceiveTokensListBuilder {
    private let userWalletInfo: UserWalletInfo

    private let sourceTokenInput: any SendSourceTokenInput
    private let receiveTokenOutput: any SendReceiveTokenOutput
    private let receiveTokenBuilder: SendReceiveTokenBuilder
    private let analyticsLogger: any SendReceiveTokensListAnalyticsLogger

    init(
        userWalletInfo: UserWalletInfo,
        sourceTokenInput: any SendSourceTokenInput,
        receiveTokenOutput: any SendReceiveTokenOutput,
        receiveTokenBuilder: SendReceiveTokenBuilder,
        analyticsLogger: any SendReceiveTokensListAnalyticsLogger
    ) {
        self.userWalletInfo = userWalletInfo
        self.sourceTokenInput = sourceTokenInput
        self.receiveTokenOutput = receiveTokenOutput
        self.receiveTokenBuilder = receiveTokenBuilder
        self.analyticsLogger = analyticsLogger
    }

    func makeReceiveTokensListViewModel(router: any SendReceiveTokensListViewRoutable) -> SendReceiveTokensListViewModel {
        let viewModel = SendReceiveTokensListViewModel(
            sourceTokenInput: sourceTokenInput,
            analyticsLogger: analyticsLogger,
            router: router
        )
        return viewModel
    }

    func makeReceiveTokenNetworkSelectorViewModel(
        coin: CoinModel,
        networks: [TokenItem],
        router: any SendReceiveTokenNetworkSelectorViewRoutable
    ) -> SendReceiveTokenNetworkSelectorViewModel {
        let viewModel = SendReceiveTokenNetworkSelectorViewModel(
            sourceTokenInput: sourceTokenInput,
            receiveTokenOutput: receiveTokenOutput,
            networks: networks,
            coin: coin,
            userWalletInfo: userWalletInfo,
            receiveTokenBuilder: receiveTokenBuilder,
            analyticsLogger: analyticsLogger,
            router: router
        )

        return viewModel
    }
}
