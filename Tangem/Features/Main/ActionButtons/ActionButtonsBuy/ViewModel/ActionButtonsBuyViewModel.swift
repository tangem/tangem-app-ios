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
            coordinator?.openAddToPortfolio(
                viewModel: .init(
                    token: token,
                    userWalletName: userWalletModel.name,
                    action: { [weak self] in
                        self?.addTokenToPortfolio(token)
                    }
                )
            )
        case .addToPortfolio(let token):
            addTokenToPortfolio(token)
        }
    }

    private func handleTokenTap(_ token: ActionButtonsTokenSelectorItem) {
        ActionButtonsAnalyticsService.trackTokenClicked(.buy, tokenSymbol: token.infoProvider.tokenItem.currencySymbol)

        let sendInput = SendInput(userWalletInfo: userWalletModel.userWalletInfo, walletModel: token.walletModel)
        let parameters = PredefinedOnrampParametersBuilder.makeMoonpayPromotionParametersIfActive()
        coordinator?.openOnramp(input: sendInput, parameters: parameters)
    }
}

// MARK: - Bind

extension ActionButtonsBuyViewModel {
    private func bind() {
        let tokenMapper = TokenItemMapper(supportedBlockchains: userWalletModel.config.supportedBlockchains)

        // accounts_fixes_needed_none
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
                // accounts_fixes_needed_none
                try userWalletModel.userTokensManager.addTokenItemPrecondition(tokenItem)

                // accounts_fixes_needed_none
                let isNotAddedToken = !userWalletModel.userTokensManager.contains(tokenItem, derivationInsensitive: true)

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

        // accounts_fixes_needed_none
        userWalletModel.userTokensManager.add(tokenItem) { [weak self] result in
            guard let self, case .success(let enrichedTokenItem) = result else { return }

            expressAvailabilityProvider.updateExpressAvailability(
                for: [enrichedTokenItem],
                forceReload: true,
                userWalletId: userWalletModel.userWalletId.stringValue
            )

            handleTokenAdding(tokenItem: enrichedTokenItem)
        }
    }

    private func handleTokenAdding(tokenItem: TokenItem) {
        // accounts_fixes_needed_none
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

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self, userWalletModel] in
            let sendInput = SendInput(userWalletInfo: userWalletModel.userWalletInfo, walletModel: walletModel)
            let parameters = PredefinedOnrampParametersBuilder.makeMoonpayPromotionParametersIfActive()
            self?.coordinator?.openOnramp(input: sendInput, parameters: parameters)
        }
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
