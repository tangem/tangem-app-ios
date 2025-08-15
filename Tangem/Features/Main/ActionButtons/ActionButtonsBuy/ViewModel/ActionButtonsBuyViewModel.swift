//
//  ActionButtonsBuyViewModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Combine
import Foundation
import BlockchainSdk
import struct TangemUIUtils.AlertBinder

final class ActionButtonsBuyViewModel: ObservableObject {
    // MARK: - Dependencies

    @Injected(\.expressAvailabilityProvider)
    private var expressAvailabilityProvider: ExpressAvailabilityProvider

    @Injected(\.hotCryptoService)
    private var hotCryptoService: HotCryptoService

    // MARK: - Published properties

    @Published var alert: AlertBinder?
    @Published private(set) var hotCryptoItems: [HotCryptoToken] = []

    // MARK: - Child viewModel

    let tokenSelectorViewModel: ActionButtonsTokenSelectorViewModel

    // MARK: - Private property

    private weak var coordinator: ActionButtonsBuyRoutable?
    private var bag = Set<AnyCancellable>()

    private let userWalletModel: UserWalletModel

    init(
        tokenSelectorViewModel: ActionButtonsTokenSelectorViewModel,
        coordinator: some ActionButtonsBuyRoutable,
        userWalletModel: some UserWalletModel
    ) {
        self.tokenSelectorViewModel = tokenSelectorViewModel
        self.coordinator = coordinator
        self.userWalletModel = userWalletModel

        bind()
    }

    func handleViewAction(_ action: Action) {
        switch action {
        case .onAppear:
            ActionButtonsAnalyticsService.trackScreenOpened(.buy)
        case .close:
            ActionButtonsAnalyticsService.trackCloseButtonTap(source: .buy)
            coordinator?.dismiss()
        case .didTapToken(let token):
            handleTokenTap(token)
        case .didTapHotCrypto(let token):
            coordinator?.openAddToPortfolio(.init(token: token, userWalletName: userWalletModel.name))
        case .addToPortfolio(let token):
            addTokenToPortfolio(token)
        }
    }

    private func handleTokenTap(_ token: ActionButtonsTokenSelectorItem) {
        ActionButtonsAnalyticsService.trackTokenClicked(.buy, tokenSymbol: token.infoProvider.tokenItem.currencySymbol)
        coordinator?.openOnramp(walletModel: token.walletModel, userWalletModel: userWalletModel)
    }
}

// MARK: - Bind

extension ActionButtonsBuyViewModel {
    private func bind() {
        let tokenMapper = TokenItemMapper(supportedBlockchains: userWalletModel.config.supportedBlockchains)

        userWalletModel
            .walletModelsManager
            .walletModelsPublisher
            .receive(on: DispatchQueue.main)
            .withWeakCaptureOf(self)
            .sink { viewModel, _ in
                viewModel.updateHotTokens(viewModel.hotCryptoItems)
            }
            .store(in: &bag)

        hotCryptoService.hotCryptoItemsPublisher
            .receive(on: DispatchQueue.main)
            .withWeakCaptureOf(self)
            .sink { viewModel, hotTokens in
                viewModel.updateHotTokens(hotTokens.map { .init(from: $0, tokenMapper: tokenMapper, imageHost: nil) })
            }
            .store(in: &bag)
    }
}

// MARK: - Hot crypto

extension ActionButtonsBuyViewModel {
    func updateHotTokens(_ hotTokens: [HotCryptoToken]) {
        hotCryptoItems = hotTokens.filter { hotToken in
            guard let tokenItem = hotToken.tokenItem else { return false }

            do {
                try userWalletModel.userTokensManager.addTokenItemPrecondition(tokenItem)

                let isNotAddedToken = !userWalletModel.userTokensManager.containsDerivationInsensitive(tokenItem)

                return isNotAddedToken
            } catch {
                return false
            }
        }

        if hotCryptoItems.isNotEmpty {
            expressAvailabilityProvider.updateExpressAvailability(
                for: hotCryptoItems.compactMap(\.tokenItem),
                forceReload: false,
                userWalletId: userWalletModel.userWalletId.stringValue
            )
        }
    }

    func addTokenToPortfolio(_ hotToken: HotCryptoToken) {
        guard let tokenItem = hotToken.tokenItem else { return }

        userWalletModel.userTokensManager.add(tokenItem) { [weak self] result in
            guard let self, result.error == nil else { return }

            expressAvailabilityProvider.updateExpressAvailability(
                for: [tokenItem],
                forceReload: true,
                userWalletId: userWalletModel.userWalletId.stringValue
            )

            handleTokenAdding(tokenItem: tokenItem)
        }
    }

    private func handleTokenAdding(tokenItem: TokenItem) {
        let walletModels = userWalletModel.walletModelsManager.walletModels

        guard
            let walletModel = walletModels.first(where: {
                let isCoinIdEquals = tokenItem.id?.lowercased() == $0.tokenItem.id?.lowercased()
                let isNetworkIdEquals = tokenItem.networkId.lowercased() == $0.tokenItem.networkId.lowercased()

                return isCoinIdEquals && isNetworkIdEquals
            }),
            expressAvailabilityProvider.canOnramp(tokenItem: walletModel.tokenItem)
        else {
            coordinator?.closeAddToPortfolio()
            return
        }

        ActionButtonsAnalyticsService.hotTokenClicked(tokenSymbol: walletModel.tokenItem.currencySymbol)

        coordinator?.closeAddToPortfolio()
        coordinator?.openOnramp(walletModel: walletModel, userWalletModel: userWalletModel)
    }
}

// MARK: - Action

extension ActionButtonsBuyViewModel {
    enum Action {
        case onAppear
        case close
        case didTapToken(ActionButtonsTokenSelectorItem)
        case didTapHotCrypto(HotCryptoToken)
        case addToPortfolio(HotCryptoToken)
    }
}
