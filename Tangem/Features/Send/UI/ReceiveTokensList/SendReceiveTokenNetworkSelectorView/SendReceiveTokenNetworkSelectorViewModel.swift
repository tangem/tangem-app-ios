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

    private weak var sourceTokenInput: SendSourceTokenInput?
    private weak var receiveTokenOutput: SendReceiveTokenOutput?
    private let networks: [TokenItem]
    private let expressRepository: ExpressRepository
    private let receiveTokenBuilder: SendReceiveTokenBuilder

    private weak var router: SendReceiveTokenNetworkSelectorViewRoutable?

    private var loadTask: Task<Void, Never>?

    init(
        sourceTokenInput: SendSourceTokenInput,
        receiveTokenOutput: SendReceiveTokenOutput,
        networks: [TokenItem],
        expressRepository: ExpressRepository,
        receiveTokenBuilder: SendReceiveTokenBuilder,
        router: SendReceiveTokenNetworkSelectorViewRoutable
    ) {
        self.sourceTokenInput = sourceTokenInput
        self.receiveTokenOutput = receiveTokenOutput
        self.networks = networks
        self.expressRepository = expressRepository
        self.receiveTokenBuilder = receiveTokenBuilder
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
                if let items = try await viewModel.getNetworksWithoutLoad() {
                    await runOnMain { viewModel.state = .success(items) }
                    return
                }

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

    private func getNetworksWithoutLoad() async throws -> [SendReceiveTokenNetworkSelectorNetworkViewData]? {
        let availableNetworks = try await availableNetworks()

        guard !availableNetworks.isEmpty else {
            return nil
        }

        let items = availableNetworks.map { network in
            return mapToSendReceiveTokenNetworkSelectorNetworkViewData(tokenItem: network)
        }

        return items
    }

    private func loadNetworks() async throws -> [SendReceiveTokenNetworkSelectorNetworkViewData] {
        guard let sourceToken = sourceTokenInput?.sourceToken else {
            throw CommonError.objectReleased
        }

        try await expressRepository.updatePairs(from: sourceToken.tokenItem.expressCurrency, to: networks.map(\.expressCurrency))

        let items = try await availableNetworks().map { network in
            return mapToSendReceiveTokenNetworkSelectorNetworkViewData(tokenItem: network)
        }

        return items
    }

    private func availableNetworks() async throws -> [TokenItem] {
        guard let sourceToken = sourceTokenInput?.sourceToken else {
            throw CommonError.objectReleased
        }

        let pairs = await expressRepository.getPairs(from: sourceToken.tokenItem.expressCurrency)
        let availableNetworks = networks.filter { network in
            pairs.contains { $0.destination == network.expressCurrency.asCurrency }
        }

        return availableNetworks
    }

    private func mapToSendReceiveTokenNetworkSelectorNetworkViewData(tokenItem: TokenItem) -> SendReceiveTokenNetworkSelectorNetworkViewData {
        SendReceiveTokenNetworkSelectorNetworkViewData(
            id: tokenItem.blockchain.networkId,
            iconURL: IconURLBuilder().tokenIconURL(id: tokenItem.blockchain.coinId, size: .large),
            name: tokenItem.blockchain.displayName,
            symbol: tokenItem.blockchain.currencySymbol
        ) { [weak self] in
            self?.userDidSelect(tokenItem: tokenItem)
        }
    }

    private func userDidSelect(tokenItem: TokenItem) {
        receiveTokenOutput?.userDidSelect(receiveToken: receiveTokenBuilder.makeSendReceiveToken(tokenItem: tokenItem))
        router?.dismissNetworkSelector(isSelected: true)
    }
}
