//
//  MainViewModelNavigationActionHandler.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

protocol NavigationActionHandling {
    func routeIncommingAction(_ action: IncomingAction) -> Bool
}

extension MainViewModel {
    struct MainViewModelNavigationActionHandler {
        @Injected(\.incomingActionManager) private var incomingActionManager: IncomingActionManaging
        let userWalletModel: (any UserWalletModel)?
        let coordinator: MainRoutable
        
        private func routeSellAction() -> Bool {
            guard let userWalletModel = userWalletModel else {
                incomingActionManager.discardIncomingAction()
                return false
            }
            
            coordinator.openSell(userWalletModel: userWalletModel)
            return true
        }
        
        private func routeBuyAction() -> Bool {
            guard isMulticurrencySupported(),
                  let userWalletModel = userWalletModel
            else {
                incomingActionManager.discardIncomingAction()
                return false
            }
            
            coordinator.openBuy(userWalletModel: userWalletModel)
            return true
        }
                
        private func routeTokenAction(tokenSymbol: String, network: String?) -> Bool {
            guard
                let uwm = userWalletModel,
                let walletModel = findWalletModel(in: uwm, tokenSymbol: tokenSymbol, network: network),
                TokenActionAvailabilityProvider(userWalletConfig: uwm.config, walletModel: walletModel).isTokenInteractionAvailable()
            else {
                incomingActionManager.discardIncomingAction()
                return false
            }
            
            coordinator.openTokenDetails(for: walletModel, userWalletModel: uwm)
            return true
        }
        
        private func routeReferralAction() -> Bool {
            guard isReferralProgramSupported(),
                  let userWalletModel = userWalletModel
            else {
                incomingActionManager.discardIncomingAction()
                return false
            }
            
            let input = ReferralInputModel(
                userWalletId: userWalletModel.userWalletId.value,
                supportedBlockchains: userWalletModel.config.supportedBlockchains,
                userTokensManager: userWalletModel.userTokensManager
            )
            
            coordinator.openReferral(input: input)
            return true
        }
        
        private func isMulticurrencySupported() -> Bool {
            guard let userWalletModel else {
                return false
            }
            
            return userWalletModel.config.hasFeature(.multiCurrency)
        }
        
        private func isReferralProgramSupported() -> Bool {
            guard let userWalletModel,
                  !userWalletModel.config.getFeatureAvailability(.referralProgram).isHidden else {
                return false
            }
            
            return true
        }
    }
}

// MARK: - NavigationActionHandling

extension MainViewModel.MainViewModelNavigationActionHandler: NavigationActionHandling {
    func routeIncommingAction(_ action: IncomingAction) -> Bool {
        guard case .navigation(let navigationAction) = action,
              coordinator.isOnMainView
        else {
            return false
        }
        
        switch navigationAction {
        case .referral:
            return routeReferralAction()
            
        case .token(let symbol, let network):
            return routeTokenAction(tokenSymbol: symbol, network: network)
            
        case .buy:
            return routeBuyAction()
            
        case .sell:
            return routeSellAction()
            
        default:
            return false
        }
    }
}


// MARK: - Helpers

extension MainViewModel.MainViewModelNavigationActionHandler {
    private func isMatch(_ model: any WalletModel, tokenSymbol: String, network: String?) -> Bool {
        let symbolMatches = model.tokenItem.currencySymbol.lowercased() == tokenSymbol.lowercased()
        let networkMatches = network.map { model.tokenItem.blockchain.blockchainId == $0.lowercased() } ?? true
        return symbolMatches && networkMatches
    }
    
    private func findWalletModel(in userWalletModel: any UserWalletModel, tokenSymbol: String, network: String?) -> (any WalletModel)? {
        userWalletModel
            .walletModelsManager
            .walletModels
            .first { isMatch($0, tokenSymbol: tokenSymbol, network: network) }
    }
}
