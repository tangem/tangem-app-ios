//
//  SendReceiveTokensListBuilder.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import TangemExpress

struct SendReceiveTokensListBuilder {
    private let sourceTokenInput: any SendSourceTokenInput
    private let receiveTokenOutput: any SendReceiveTokenOutput
    private let expressRepository: any ExpressRepository
    private let receiveTokenBuilder: SendReceiveTokenBuilder

    init(
        sourceTokenInput: any SendSourceTokenInput,
        receiveTokenOutput: any SendReceiveTokenOutput,
        expressRepository: any ExpressRepository,
        receiveTokenBuilder: SendReceiveTokenBuilder
    ) {
        self.sourceTokenInput = sourceTokenInput
        self.receiveTokenOutput = receiveTokenOutput
        self.expressRepository = expressRepository
        self.receiveTokenBuilder = receiveTokenBuilder
    }

    func makeReceiveTokensListViewModel(router: any SendReceiveTokensListViewRoutable) -> SendReceiveTokensListViewModel {
        let viewModel = SendReceiveTokensListViewModel(sourceTokenInput: sourceTokenInput, router: router)
        return viewModel
    }

    func makeReceiveTokenNetworkSelectorViewModel(
        networks: [TokenItem],
        router: any SendReceiveTokenNetworkSelectorViewRoutable
    ) -> SendReceiveTokenNetworkSelectorViewModel {
        let viewModel = SendReceiveTokenNetworkSelectorViewModel(
            sourceTokenInput: sourceTokenInput,
            receiveTokenOutput: receiveTokenOutput,
            networks: networks,
            expressRepository: expressRepository,
            receiveTokenBuilder: receiveTokenBuilder,
            router: router
        )

        return viewModel
    }
}
