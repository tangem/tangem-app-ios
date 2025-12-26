//
//  AccountsAwareActionButtonsBuyViewModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Combine
import Foundation
import BlockchainSdk
import TangemFoundation
import struct TangemUIUtils.AlertBinder

final class AccountsAwareActionButtonsBuyViewModel: ObservableObject {
    // MARK: - Dependencies

    @Injected(\.hotCryptoService) private var hotCryptoService: HotCryptoService

    // MARK: - ViewState

    @Published var alert: AlertBinder?
    @Published private(set) var hotCryptoItems: [HotCryptoToken] = []

    let tokenSelectorViewModel: AccountsAwareTokenSelectorViewModel

    // MARK: - Private

    private let userWalletModels: [UserWalletModel]
    private weak var coordinator: ActionButtonsBuyRoutable?

    init(
        userWalletModels: [UserWalletModel],
        tokenSelectorViewModel: AccountsAwareTokenSelectorViewModel,
        coordinator: some ActionButtonsBuyRoutable
    ) {
        self.userWalletModels = userWalletModels
        self.tokenSelectorViewModel = tokenSelectorViewModel
        self.coordinator = coordinator

        tokenSelectorViewModel.setup(with: self)
        bind()
    }

    func onAppear() {
        ActionButtonsAnalyticsService.trackScreenOpened(.buy)
    }

    func close() {
        ActionButtonsAnalyticsService.trackCloseButtonTap(source: .buy)
        coordinator?.dismiss()
    }

    func userDidTapHotCryptoToken(_ token: HotCryptoToken) {
        ActionButtonsAnalyticsService.hotTokenClicked(tokenSymbol: token.tokenItem?.currencySymbol ?? token.name)
        coordinator?.openAddHotToken(hotToken: token, userWalletModels: userWalletModels)
    }
}

// MARK: - Private

private extension AccountsAwareActionButtonsBuyViewModel {
    func bind() {
        hotCryptoService.hotCryptoItemsPublisher
            .map { [weak self] in self?.mapHotCryptoItems($0) ?? [] }
            .receiveOnMain()
            .assign(to: &$hotCryptoItems)
    }

    func mapHotCryptoItems(_ items: [HotCryptoDTO.Response.HotToken]) -> [HotCryptoToken] {
        let allSupportedBlockchains = Set(userWalletModels.flatMap { $0.config.supportedBlockchains })
        let tokenMapper = TokenItemMapper(supportedBlockchains: allSupportedBlockchains)

        let mappedTokens = items.map { HotCryptoToken(from: $0, tokenMapper: tokenMapper, imageHost: nil) }
        return filterHotTokens(mappedTokens)
    }

    func filterHotTokens(_ hotTokens: [HotCryptoToken]) -> [HotCryptoToken] {
        hotTokens.filter { hotToken in
            guard let tokenItem = hotToken.tokenItem, let coinId = tokenItem.id else { return false }

            let network = NetworkModel(
                networkId: tokenItem.networkId,
                contractAddress: tokenItem.contractAddress,
                decimalCount: tokenItem.decimalCount
            )

            let isAddedOnAll = TokenAdditionChecker.isTokenAddedOnNetworksInAllAccounts(
                coinId: coinId,
                availableNetworks: [network],
                userWalletModels: userWalletModels
            )

            return !isAddedOnAll
        }
    }
}

// MARK: - AccountsAwareTokenSelectorViewModelOutput

extension AccountsAwareActionButtonsBuyViewModel: AccountsAwareTokenSelectorViewModelOutput {
    func usedDidSelect(item: AccountsAwareTokenSelectorItem) {
        ActionButtonsAnalyticsService.trackTokenClicked(.buy, tokenSymbol: item.walletModel.tokenItem.currencySymbol)

        let sendInput = SendInput(userWalletInfo: item.userWalletInfo, walletModel: item.walletModel)
        let parameters = PredefinedOnrampParametersBuilder.makeMoonpayPromotionParametersIfActive()
        coordinator?.openOnramp(input: sendInput, parameters: parameters)
    }
}
