//
//  SendReceiveTokenNetworkSelectorViewModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import TangemFoundation
import TangemExpress
import TangemUI

protocol SendReceiveTokenNetworkSelectorViewRoutable: AnyObject {
    func dismissNetworkSelector(isSelected: Bool)
}

class SendReceiveTokenNetworkSelectorViewModel: ObservableObject, FloatingSheetContentViewModel {
    @Published var state: LoadingResult<[SendReceiveTokenNetworkSelectorNetworkViewData], Error> = .loading

    private let tokenItem: TokenItem
    private let networks: [TokenItem]
    private let expressRepository: ExpressRepository
    private let receiveTokenBuilder: SendReceiveTokenBuilder
    private weak var output: SendReceiveTokenOutput?
    private weak var router: SendReceiveTokenNetworkSelectorViewRoutable?

    private var loadTask: Task<Void, Never>?

    init(
        tokenItem: TokenItem,
        networks: [TokenItem],
        expressRepository: ExpressRepository,
        receiveTokenBuilder: SendReceiveTokenBuilder,
        output: SendReceiveTokenOutput,
        router: SendReceiveTokenNetworkSelectorViewRoutable
    ) {
        self.tokenItem = tokenItem
        self.networks = networks
        self.expressRepository = expressRepository
        self.receiveTokenBuilder = receiveTokenBuilder
        self.output = output
        self.router = router

        load()
    }

    func dismiss() {
        loadTask?.cancel()
        router?.dismissNetworkSelector(isSelected: false)
    }

    private func load() {
        loadTask = runTask(in: self) { viewModel in
            do {
                // We use the minimum loading time here
                // Otherwise the bottom sheet is jumping
                let items = try await runTask(withMinimumTime: 1) {
                    try await viewModel.loadNetworks()
                }.value

                await runOnMain { viewModel.state = .success(items) }
            } catch {
                await runOnMain { viewModel.state = .failure(error) }
            }
        }
    }

    private func loadNetworks() async throws -> [SendReceiveTokenNetworkSelectorNetworkViewData] {
        let source = tokenItem.expressCurrency
        try await expressRepository.updatePairs(from: source, to: networks.map(\.expressCurrency))
        let pairs = await expressRepository.getPairs(from: source)

        let items = networks.map { network in
            let isAvailable = pairs.contains(where: { $0.destination == network.expressCurrency.asCurrency })
            return mapToSendReceiveTokenNetworkSelectorNetworkViewData(tokenItem: network, isAvailable: isAvailable)
        }

        return items
    }

    private func mapToSendReceiveTokenNetworkSelectorNetworkViewData(tokenItem: TokenItem, isAvailable: Bool) -> SendReceiveTokenNetworkSelectorNetworkViewData {
        SendReceiveTokenNetworkSelectorNetworkViewData(
            id: tokenItem.blockchain.networkId,
            iconURL: IconURLBuilder().tokenIconURL(id: tokenItem.blockchain.coinId, size: .large),
            name: tokenItem.blockchain.displayName,
            symbol: tokenItem.blockchain.currencySymbol,
            isAvailable: isAvailable
        ) { [weak self] in
            self?.userDidSelect(tokenItem: tokenItem)
        }
    }

    private func userDidSelect(tokenItem: TokenItem) {
        output?.userDidSelect(receiveToken: receiveTokenBuilder.makeSendReceiveToken(tokenItem: tokenItem))
        router?.dismissNetworkSelector(isSelected: true)
    }
}
