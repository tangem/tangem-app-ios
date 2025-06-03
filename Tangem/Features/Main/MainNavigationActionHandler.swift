//
//  MainNavigationActionHandler.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

protocol NavigationActionHandling {
    func routeIncommingAction(_ action: IncomingAction) -> Bool
}

extension MainViewModel {
    struct MainNavigationActionHandler {
        @Injected(\.incomingActionManager) private var incomingActionManager: IncomingActionManaging
        @Injected(\.appLockController) private var appLockController: AppLockController
        @Injected(\.overlayContentStateController) private var bottomSheetStateController: OverlayContentStateController
        @Injected(\.mainBottomSheetUIManager) private var mainBottomSheetUIManager: MainBottomSheetUIManager

        let userWalletModel: (any UserWalletModel)?
        weak var coordinator: MainRoutable?

        private func routeSellAction() -> Bool {
            guard let userWalletModel = userWalletModel else {
                incomingActionManager.discardIncomingAction()
                return false
            }

            coordinator?.openSell(userWalletModel: userWalletModel)
            return true
        }

        private func routeBuyAction() -> Bool {
            guard isFeatureSupported(feature: .multiCurrency),
                  let userWalletModel = userWalletModel
            else {
                incomingActionManager.discardIncomingAction()
                return false
            }

            coordinator?.openBuy(userWalletModel: userWalletModel)
            return true
        }

        private func routeTokenAction(tokenSymbol: String, network: String?) -> Bool {
            guard
                let coordinator,
                let userWalletModel = userWalletModel,
                let walletModel = findWalletModel(in: userWalletModel, tokenSymbol: tokenSymbol, network: network),
                TokenActionAvailabilityProvider(userWalletConfig: userWalletModel.config, walletModel: walletModel).isTokenInteractionAvailable()
            else {
                incomingActionManager.discardIncomingAction()
                return false
            }

            coordinator.openTokenDetails(for: walletModel, userWalletModel: userWalletModel)
            return true
        }

        private func routeReferralAction() -> Bool {
            guard
                let coordinator,
                isFeatureSupported(feature: .referralProgram),
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

        private func routeStaking(tokenSymbol: String) -> Bool {
            guard
                let coordinator,
                isFeatureSupported(feature: .staking),
                let userWalletModel = userWalletModel,
                let walletModel = findWalletModel(in: userWalletModel, tokenSymbol: tokenSymbol, network: nil),
                let stakingManager = walletModel.stakingManager
            else {
                incomingActionManager.discardIncomingAction()
                return false
            }

            let options = StakingDetailsCoordinator.Options(
                userWalletModel: userWalletModel,
                walletModel: walletModel,
                manager: stakingManager
            )

            coordinator.openStaking(options: options)
            return true
        }
    }
}

// MARK: - NavigationActionHandling

extension MainViewModel.MainNavigationActionHandler: NavigationActionHandling {
    func routeIncommingAction(_ action: IncomingAction) -> Bool {
        guard
            let coordinator,
            case .navigation(let navigationAction) = action,
            !appLockController.isLocked,
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

        case .staking(let symbol):
            return routeStaking(tokenSymbol: symbol)

        default:
            return false
        }
    }
}

// MARK: - Helpers

extension MainViewModel.MainNavigationActionHandler {
    private func isFeatureSupported(feature: UserWalletFeature) -> Bool {
        guard let userWalletModel,
              !userWalletModel.config.getFeatureAvailability(feature).isHidden else {
            return false
        }

        return true
    }

    private func isMatch(_ model: any WalletModel, tokenSymbol: String, network: String?) -> Bool {
        let symbolMatches = model.tokenItem.currencySymbol.lowercased() == tokenSymbol.lowercased()
        let networkMatches = network.map { model.tokenItem.blockchain.networkId == $0.lowercased() } ?? true
        return symbolMatches && networkMatches
    }

    private func findWalletModel(in userWalletModel: any UserWalletModel, tokenSymbol: String, network: String?) -> (any WalletModel)? {
        userWalletModel
            .walletModelsManager
            .walletModels
            .first { isMatch($0, tokenSymbol: tokenSymbol, network: network) }
    }
}
