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
import TangemLocalization

protocol SendReceiveTokenNetworkSelectorViewRoutable: AnyObject {
    func dismissNetworkSelector(isSelected: Bool)
}

class SendReceiveTokenNetworkSelectorViewModel: ObservableObject, FloatingSheetContentViewModel {
    @Injected(\.expressPairsRepository)
    private var expressPairsRepository: ExpressPairsRepository

    @Published var notification: NotificationViewInput?
    @Published var state: LoadingResult<[SendReceiveTokenNetworkSelectorNetworkViewData], String> = .loading

    var notSupportedTitle: String {
        // It's should be the same token name in all token items
        if let tokenName = networks.first?.token?.name {
            return Localization.expressSwapNotSupportedTitle(tokenName)
        }

        return Localization.commonError
    }

    private weak var sourceTokenInput: SendSourceTokenInput?
    private weak var receiveTokenOutput: SendReceiveTokenOutput?
    private let networks: [TokenItem]
    private let coin: CoinModel
    private let userWalletInfo: UserWalletInfo
    private let receiveTokenBuilder: SendReceiveTokenBuilder
    private let analyticsLogger: SendReceiveTokensListAnalyticsLogger

    private weak var router: SendReceiveTokenNetworkSelectorViewRoutable?

    private var loadTask: Task<Void, Never>?

    init(
        sourceTokenInput: SendSourceTokenInput,
        receiveTokenOutput: SendReceiveTokenOutput,
        networks: [TokenItem],
        coin: CoinModel,
        userWalletInfo: UserWalletInfo,
        receiveTokenBuilder: SendReceiveTokenBuilder,
        analyticsLogger: SendReceiveTokensListAnalyticsLogger,
        router: SendReceiveTokenNetworkSelectorViewRoutable
    ) {
        self.sourceTokenInput = sourceTokenInput
        self.receiveTokenOutput = receiveTokenOutput
        self.networks = networks
        self.coin = coin
        self.userWalletInfo = userWalletInfo
        self.receiveTokenBuilder = receiveTokenBuilder
        self.analyticsLogger = analyticsLogger
        self.router = router

        load()
        setupNotification()
    }

    func dismiss() {
        loadTask?.cancel()
        router?.dismissNetworkSelector(isSelected: false)
    }

    private func setupNotification() {
        notification = NotificationsFactory().buildNotificationInput(
            for: SendReceiveTokensListNotification.irreversibleLossNotification
        )
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
            } catch Error.supportedNetworksIsEmpty {
                viewModel.analyticsLogger.logSendSwapCantSwapThisToken(token: viewModel.coin.symbol)
                await runOnMain { viewModel.state = .failure(Localization.expressSwapNotSupportedText) }
            } catch {
                await runOnMain { viewModel.state = .failure(error.localizedDescription) }
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

        try await expressPairsRepository.updatePairs(
            from: sourceToken.tokenItem.expressCurrency,
            to: networks.map(\.expressCurrency),
            userWalletInfo: userWalletInfo
        )

        let items = try await availableNetworks().map { network in
            return mapToSendReceiveTokenNetworkSelectorNetworkViewData(tokenItem: network)
        }

        if items.isEmpty {
            throw Error.supportedNetworksIsEmpty
        }

        return items
    }

    private func availableNetworks() async throws -> [TokenItem] {
        guard let sourceToken = sourceTokenInput?.sourceToken else {
            throw CommonError.objectReleased
        }

        let pairs = await expressPairsRepository.getPairs(from: sourceToken.tokenItem.expressCurrency)
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
            network: tokenItem.contractName,
            isMainNetwork: tokenItem.isBlockchain
        ) { [weak self] in
            self?.userDidSelect(tokenItem: tokenItem)
        }
    }

    private func userDidSelect(tokenItem: TokenItem) {
        receiveTokenOutput?.userDidRequestSelect(
            receiveToken: receiveTokenBuilder.makeSendReceiveToken(tokenItem: tokenItem)
        ) { [weak self] selected in
            self?.analyticsLogger.logTokenChosen(token: tokenItem)
            self?.router?.dismissNetworkSelector(isSelected: selected)
        }
    }
}

extension SendReceiveTokenNetworkSelectorViewModel {
    enum Error: LocalizedError {
        case supportedNetworksIsEmpty
    }
}
