//
//  ActionButtonsBuyViewModel.swift
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

final class ActionButtonsBuyViewModel: ObservableObject {
    // MARK: - Dependencies

    @Injected(\.hotCryptoService) private var hotCryptoService: HotCryptoService

    // MARK: - ViewState

    @Published var alert: AlertBinder?
    @Published private(set) var hotCryptoItems: [HotCryptoToken] = []

    let tokenSelectorViewModel: TokenSelectorViewModel

    // MARK: - Private

    private let userWalletModels: [UserWalletModel]
    private weak var coordinator: ActionButtonsBuyRoutable?

    init(
        userWalletModels: [UserWalletModel],
        tokenSelectorViewModel: TokenSelectorViewModel,
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
        let scopeWalletModels = hotCryptoScopeWalletModels(selectedChipId: tokenSelectorViewModel.selectedChipId)
        coordinator?.openAddHotToken(hotToken: token, userWalletModels: scopeWalletModels)
    }
}

// MARK: - Private

private extension ActionButtonsBuyViewModel {
    func bind() {
        hotCryptoService.hotCryptoItemsPublisher
            .combineLatest(tokenSelectorViewModel.$selectedChipId)
            .map { [weak self] items, selectedChipId in
                self?.mapHotCryptoItems(items, selectedChipId: selectedChipId) ?? []
            }
            .receiveOnMain()
            .assign(to: &$hotCryptoItems)
    }

    func mapHotCryptoItems(_ items: [HotCryptoDTO.Response.HotToken], selectedChipId: String?) -> [HotCryptoToken] {
        let scopeWalletModels = hotCryptoScopeWalletModels(selectedChipId: selectedChipId)

        guard scopeWalletModels.isNotEmpty else {
            return []
        }

        let supportedBlockchains = Set(scopeWalletModels.flatMap { $0.config.supportedBlockchains })
        let tokenMapper = TokenItemMapper(supportedBlockchains: supportedBlockchains)

        let mappedTokens = items.map { HotCryptoToken(from: $0, tokenMapper: tokenMapper, imageHost: nil) }
        return filterHotTokens(mappedTokens, userWalletModels: scopeWalletModels)
    }

    func hotCryptoScopeWalletModels(selectedChipId: String?) -> [UserWalletModel] {
        let scopeWalletModels: [UserWalletModel]
        if let selectedChipId,
           let selected = userWalletModels.first(where: { $0.userWalletId.stringValue == selectedChipId }) {
            scopeWalletModels = [selected]
        } else {
            scopeWalletModels = userWalletModels
        }

        return scopeWalletModels.filter { $0.config.makeActionButtonsRole().providesHotCryptoTokens }
    }

    func filterHotTokens(_ hotTokens: [HotCryptoToken], userWalletModels: [UserWalletModel]) -> [HotCryptoToken] {
        hotTokens.filter { hotToken in
            guard let tokenItem = hotToken.tokenItem else { return false }

            let isAddedOnAll = TokenAdditionChecker.areTokenItemsAddedInAllAccounts(
                userWalletModels: userWalletModels
            ) { _, _ in
                [tokenItem]
            }

            return !isAddedOnAll
        }
    }
}

// MARK: - TokenSelectorViewModelOutput

extension ActionButtonsBuyViewModel: TokenSelectorViewModelOutput {
    func userDidSelect(item: TokenSelectorItem) {
        guard let walletModel = item.kind.walletModel else {
            return
        }

        // Card-linked gating happens in AddFundsViewModel, so no extra gate is needed here.
        coordinator?.openAddFunds(userWalletInfo: item.userWalletInfo, walletModel: walletModel)
    }
}
