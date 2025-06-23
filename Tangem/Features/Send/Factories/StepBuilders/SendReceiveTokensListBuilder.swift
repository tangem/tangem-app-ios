//
//  SendReceiveTokensListBuilder.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import TangemExpress

struct SendReceiveTokensListBuilder {
    typealias IO = (input: SendReceiveTokenInput, output: SendReceiveTokenOutput)

    private let io: IO
    private let tokenItem: TokenItem
    private let expressRepository: ExpressRepository
    private let receiveTokenBuilder: SendReceiveTokenBuilder

    init(
        io: IO,
        tokenItem: TokenItem,
        expressRepository: ExpressRepository,
        receiveTokenBuilder: SendReceiveTokenBuilder
    ) {
        self.io = io
        self.tokenItem = tokenItem
        self.expressRepository = expressRepository
        self.receiveTokenBuilder = receiveTokenBuilder
    }

    func makeReceiveTokensListViewModel(router: any SendReceiveTokensListViewRoutable) -> SendReceiveTokensListViewModel {
        let viewModel = SendReceiveTokensListViewModel(router: router)
        return viewModel
    }

    func makeReceiveTokenNetworkSelectorViewModel(networks: [TokenItem], router: any SendReceiveTokenNetworkSelectorViewRoutable) -> SendReceiveTokenNetworkSelectorViewModel {
        let viewModel = SendReceiveTokenNetworkSelectorViewModel(
            tokenItem: tokenItem,
            networks: networks,
            expressRepository: expressRepository,
            receiveTokenBuilder: receiveTokenBuilder,
            output: io.output,
            router: router
        )

        return viewModel
    }
}
