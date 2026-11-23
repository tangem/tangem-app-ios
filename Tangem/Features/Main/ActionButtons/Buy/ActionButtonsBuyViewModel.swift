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

    @Injected(\.userWalletRepository) private var userWalletRepository: UserWalletRepository

    // MARK: - ViewState

    @Published var alert: AlertBinder?
    @Published private(set) var isPulseResultEmpty: Bool = false

    let tokenSelectorViewModel: TokenSelectorViewModel
    let pulseMarketWidgetViewModel: PulseMarketWidgetViewModel?

    var shouldShowSearchEmptyContent: Bool {
        pulseMarketWidgetViewModel == nil || isPulseResultEmpty
    }

    // MARK: - Private

    private weak var coordinator: (any ActionButtonsBuyRoutable & AddTokenFlowRedesignedRoutable)?

    init(
        tokenSelectorViewModel: TokenSelectorViewModel,
        pulseMarketWidgetViewModel: PulseMarketWidgetViewModel?,
        coordinator: some ActionButtonsBuyRoutable & AddTokenFlowRedesignedRoutable
    ) {
        self.tokenSelectorViewModel = tokenSelectorViewModel
        self.pulseMarketWidgetViewModel = pulseMarketWidgetViewModel
        self.coordinator = coordinator

        tokenSelectorViewModel.setup(with: self)
        pulseMarketWidgetViewModel?.setup(router: self)
        bind()
    }

    func onAppear() {
        ActionButtonsAnalyticsService.trackScreenOpened(.buy)
        pulseMarketWidgetViewModel?.resumeQuotesUpdates()
    }

    func onDisappear() {
        pulseMarketWidgetViewModel?.pauseQuotesUpdates()
    }

    func close() {
        ActionButtonsAnalyticsService.trackCloseButtonTap(source: .buy)
        coordinator?.dismiss()
    }
}

// MARK: - Private

private extension ActionButtonsBuyViewModel {
    func bind() {
        guard let pulseMarketWidgetViewModel else { return }

        pulseMarketWidgetViewModel.bind(searchTextPublisher: tokenSelectorViewModel.$searchText)

        pulseMarketWidgetViewModel.$tokenViewModelsState
            .map { state -> Bool in
                guard case .success(let items) = state else { return false }
                return items.isEmpty
            }
            .removeDuplicates()
            .receiveOnMain()
            .assign(to: &$isPulseResultEmpty)
    }
}

// MARK: - Add token

private extension ActionButtonsBuyViewModel {
    @MainActor
    func makeAddTokenViewModel(for tokenInfo: MarketsTokenModel) -> AddTokenFlowRedesignedViewModel? {
        guard
            let userWalletModel = selectedUserWalletModel(),
            var networks = tokenInfo.networks,
            !isTokenAddedInAllAccounts(tokenInfo, userWalletModel: userWalletModel)
        else {
            return nil
        }

        if tokenInfo.id == Blockchain.ethereum(testnet: false).coinId {
            let l2Items = SupportedBlockchains.l2Blockchains.map {
                NetworkModel(networkId: $0.networkId, contractAddress: nil, decimalCount: nil)
            }
            networks.append(contentsOf: l2Items)
        }

        let inputData = MarketsAddTokenFlowConfigurationFactory.InputData(
            coinId: tokenInfo.id,
            coinName: tokenInfo.name,
            coinSymbol: tokenInfo.symbol,
            networks: networks
        )

        let configuration = MarketsAddTokenFlowConfigurationFactory.makeForPulseWidget(
            inputData: inputData,
            onConfirm: { [weak self] tokenItem, accountSelectorCell in
                self?.openAddFunds(for: tokenItem, accountSelectorCell: accountSelectorCell)
            }
        )

        return AddTokenFlowRedesignedViewModel(
            userWalletModels: userWalletRepository.models.filter { !$0.isUserWalletLocked },
            preferredWalletId: userWalletModel.userWalletId,
            configuration: configuration,
            coordinator: coordinator
        )
    }

    func selectedUserWalletModel() -> UserWalletModel? {
        guard let selectedWalletId = tokenSelectorViewModel.selectedWalletId else {
            return nil
        }

        return userWalletRepository.models.first { $0.userWalletId == selectedWalletId }
    }

    func isTokenAddedInAllAccounts(_ tokenInfo: MarketsTokenModel, userWalletModel: UserWalletModel) -> Bool {
        TokenAdditionChecker.areTokenItemsAddedInAllAccounts(userWalletModels: [userWalletModel]) { account, supportedBlockchains in
            MarketsTokenItemsProvider.calculateTokenItems(
                coinId: tokenInfo.id,
                coinName: tokenInfo.name,
                coinSymbol: tokenInfo.symbol,
                networks: tokenInfo.networks ?? [],
                supportedBlockchains: supportedBlockchains,
                cryptoAccount: account
            )
        }
    }

    func openAddFunds(for tokenItem: TokenItem, accountSelectorCell: AccountSelectorCellModel) {
        Task { @MainActor [weak self] in
            let walletModel = await accountSelectorCell.cryptoAccountModel
                .walletModelsManager.waitForWalletModel(for: tokenItem)

            guard let walletModel else { return }

            self?.coordinator?.close()
            self?.coordinator?.openAddFunds(
                userWalletInfo: accountSelectorCell.userWalletModel.userWalletInfo,
                walletModel: walletModel
            )
        }
    }
}

// MARK: - PulseMarketWidgetRoutable

extension ActionButtonsBuyViewModel: PulseMarketWidgetRoutable {
    @MainActor
    func openMarketsTokenDetails(for tokenInfo: MarketsTokenModel) {
        guard let addTokenViewModel = makeAddTokenViewModel(for: tokenInfo) else {
            coordinator?.openMarketsTokenDetails(for: tokenInfo)
            return
        }

        coordinator?.openAddToken(viewModel: addTokenViewModel)
    }

    func openSeeAllPulseMarketWidget(with orderType: MarketsListOrderType) {
        assertionFailure("See all is hidden in the Buy pulse widget, so this is never invoked.")
    }
}

// MARK: - TokenSelectorViewModelOutput

extension ActionButtonsBuyViewModel: TokenSelectorViewModelOutput {
    func userDidSelect(item: TokenSelectorItem) {
        guard let walletModel = item.kind.walletModel else {
            return
        }

        // The incomplete-backup top-up warning is shown downstream in AddFundsViewModel, so no extra check is needed here.
        coordinator?.openAddFunds(userWalletInfo: item.userWalletInfo, walletModel: walletModel)
    }
}
