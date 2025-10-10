//
//  NewNewActionButtonsBuyViewModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Combine
import Foundation
import struct TangemUIUtils.AlertBinder

final class NewActionButtonsBuyViewModel: ObservableObject {
    // MARK: - Dependencies

//    [REDACTED_USERNAME](\.expressAvailabilityProvider)
//    private var expressAvailabilityProvider: ExpressAvailabilityProvider

    @Injected(\.hotCryptoService)
    private var hotCryptoService: HotCryptoService

    // MARK: - Published properties

    @Published var alert: AlertBinder?
    @Published private(set) var hotCryptoItems: [HotCryptoToken] = []

    // MARK: - Child viewModel

    let tokenSelectorContentProvider = CommonNewTokenSelectorViewModelContentProvider()
    let filter = CommonNewTokenSelectorViewModelSearchFilter()
    let availabilityProvider = OnrampNewTokenSelectorViewModelAvailabilityProvider()
    lazy var tokenSelectorViewModel = NewTokenSelectorViewModel(
        provider: tokenSelectorContentProvider,
        filter: filter,
        availabilityProvider: availabilityProvider,
        output: self
    )

    // MARK: - Private property

    private weak var coordinator: ActionButtonsBuyRoutable?
    // private var bag = Set<AnyCancellable>()

    init(coordinator: some ActionButtonsBuyRoutable) {
        self.coordinator = coordinator

        // bind()
    }

    func onAppear() {
        ActionButtonsAnalyticsService.trackScreenOpened(.buy)
    }

    func close() {
        ActionButtonsAnalyticsService.trackCloseButtonTap(source: .buy)
        coordinator?.dismiss()
    }

    func userDidTapHotCryptoToken(_ token: HotCryptoToken) {
        // [REDACTED_TODO_COMMENT]
        // coordinator?.openAddToPortfolio(.init(token: token, userWalletName: userWalletModel.name))
    }

    func userDidRequestAddHotCryptoToken(_ token: HotCryptoToken) {
        // [REDACTED_TODO_COMMENT]
        // coordinator?.openAddToPortfolio(.init(token: token, userWalletName: userWalletModel.name))
    }
}

// MARK: - NewTokenSelectorViewModelOutput

extension NewActionButtonsBuyViewModel: NewTokenSelectorViewModelOutput {
    func usedDidSelect(item: NewTokenSelectorItem) {
        ActionButtonsAnalyticsService.trackTokenClicked(.buy, tokenSymbol: item.walletModel.tokenItem.currencySymbol)
        coordinator?.openOnramp(
            input: .init(
                userWalletInfo: item.wallet.userWalletInfo,
                walletModel: item.walletModel,
                expressInput: .init(
                    userWalletInfo: item.wallet.userWalletInfo,
                    refcode: .none, // [REDACTED_TODO_COMMENT]
                    walletModelsManager: item.account.walletModelsManager
                )
            )
        )
    }
}

// MARK: - Bind

/*
 extension NewActionButtonsBuyViewModel {
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

 // MARK: - NewTokenSelectorViewModelOutput

 extension NewActionButtonsBuyViewModel: NewTokenSelectorViewModelOutput {
     func usedDidSelect(item: NewTokenSelectorItem) {}
 }

 // MARK: - Hot crypto

 extension NewActionButtonsBuyViewModel {
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

 extension NewActionButtonsBuyViewModel {
     enum Action {
         case onAppear
         case close
         case didTapToken(ActionButtonsTokenSelectorItem)
         case didTapHotCrypto(HotCryptoToken)
         case addToPortfolio(HotCryptoToken)
     }
 }
 */
