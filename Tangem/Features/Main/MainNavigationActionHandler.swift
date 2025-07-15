//
//  MainNavigationActionHandler.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import BlockchainSdk

extension MainCoordinator {
    final class MainNavigationActionHandler {
        // MARK: - Properties

        @Injected(\.incomingActionManager) private var incomingActionManager: IncomingActionManaging
        @Injected(\.appLockController) private var appLockController: AppLockController
        @Injected(\.mainBottomSheetUIManager) private var mainBottomSheetUIManager: MainBottomSheetUIManager
        @Injected(\.userWalletRepository) private var userWalletRepository: UserWalletRepository
        @Injected(\.overlayContentStateController) private var bottomSheetStateController: OverlayContentStateController

        weak var coordinator: MainRoutable?

        // MARK: - Public Implementation

        func becomeIncomingActionsResponder() {
            incomingActionManager.becomeFirstResponder(self)
        }

        // MARK: - Private Implementation

        private func routeIncomingAction(_ action: IncomingAction) -> Bool {
            guard coordinator != nil,
                  case .navigation(let navigationAction) = action,
                  !userWalletRepository.isLocked
            else {
                return false
            }

            // [REDACTED_TODO_COMMENT]
            // A temporary crutch until a decision is made on how to handle a scenario where selected wallet does not match the wallet
            // from a push
            if let paramWalletId = navigationAction.params.userWalletId,
               let selectedWalletId = userWalletRepository.selectedModel?.userWalletId.stringValue,
               paramWalletId != selectedWalletId {
                return false
            }

            switch navigationAction.destination {
            case .referral:
                return routeReferralAction()

            case .token:
                return routeTokenAction(params: navigationAction.params)

            case .buy:
                return routeBuyAction()

            case .sell:
                return routeSellAction()

            case .staking:
                return routeStakingAction(params: navigationAction.params)

            case .markets:
                return routeMarketAction()

            case .tokenChart:
                return routeTokenChartAction(params: navigationAction.params)

            case .link:
                return routeLinkAction(params: navigationAction.params)

            case .swap:
                return routeSwapAction()
            }
        }

        private func routeLinkAction(params: DeeplinkNavigationAction.Params) -> Bool {
            guard let coordinator,
                  let externalUrl = params.url
            else {
                incomingActionManager.discardIncomingAction()
                return false
            }

            // If the action remains pending, SafariManager will try to become the first responder on init,
            // which causes a recursive call and crash. To prevent this, we discard the pending action
            // before triggering the deep link.
            incomingActionManager.discardIncomingAction()
            coordinator.openDeepLink(.externalLink(url: externalUrl))
            return true
        }

        private func routeTokenChartAction(params: DeeplinkNavigationAction.Params) -> Bool {
            guard let coordinator,
                  let tokenId = params.tokenId
            else {
                incomingActionManager.discardIncomingAction()
                return false
            }

            coordinator.openDeepLink(.marketsTokenDetails(tokenId: tokenId))
            return true
        }

        private func routeMarketAction() -> Bool {
            coordinator?.openDeepLink(.market)
            return true
        }

        private func routeSwapAction() -> Bool {
            guard let userWalletModel = userWalletRepository.selectedModel else {
                incomingActionManager.discardIncomingAction()
                return false
            }

            coordinator?.openDeepLink(.swap(userWalletModel: userWalletModel))
            return true
        }

        private func routeSellAction() -> Bool {
            guard let userWalletModel = userWalletRepository.selectedModel else {
                incomingActionManager.discardIncomingAction()
                return false
            }

            coordinator?.openDeepLink(.sell(userWalletModel: userWalletModel))
            return true
        }

        private func routeBuyAction() -> Bool {
            guard isFeatureSupported(feature: .multiCurrency),
                  let userWalletModel = userWalletRepository.selectedModel
            else {
                incomingActionManager.discardIncomingAction()
                return false
            }

            coordinator?.openDeepLink(.buy(userWalletModel: userWalletModel))
            return true
        }

        private func routeTokenAction(params: DeeplinkNavigationAction.Params) -> Bool {
            guard
                let coordinator,
                let userWalletModel = userWalletRepository.selectedModel,
                let tokenId = params.tokenId,
                let networkId = params.networkId,
                let walletModel = findWalletModel(in: userWalletModel, tokenId: tokenId, networkId: networkId, derivation: params.derivationPath),
                TokenActionAvailabilityProvider(userWalletConfig: userWalletModel.config, walletModel: walletModel).isTokenInteractionAvailable()
            else {
                incomingActionManager.discardIncomingAction()
                return false
            }

            if case .some(let type) = params.type, type == .onrampStatusUpdate || type == .swapStatusUpdate, let txId = params.transactionId {
                return routeExpressTransactionStatusAction(
                    coordinator: coordinator,
                    deeplinkType: type,
                    transactionId: txId,
                    walletModel: walletModel,
                    userWalletModel: userWalletModel
                )
            } else {
                coordinator.openDeepLink(.tokenDetails(walletModel: walletModel, userWalletModel: userWalletModel))
                return true
            }
        }

        private func routeExpressTransactionStatusAction(
            coordinator: MainRoutable,
            deeplinkType: IncomingActionConstants.DeeplinkType,
            transactionId: String,
            walletModel: any WalletModel,
            userWalletModel: UserWalletModel
        ) -> Bool {
            let transactionType: PendingTransactionDetails.TransactionType

            switch deeplinkType {
            case .onrampStatusUpdate:
                transactionType = .onramp
            case .swapStatusUpdate:
                transactionType = .swap
            case .incomeTransaction, .promo:
                // Transaction status deeplinks are not supported for these types
                return false
            }

            coordinator.openDeepLink(
                .expressTransactionStatus(
                    walletModel: walletModel,
                    userWalletModel: userWalletModel,
                    transactionDetails: .init(type: transactionType, id: transactionId)
                )
            )

            return true
        }

        private func routeReferralAction() -> Bool {
            guard let coordinator,
                  isFeatureSupported(feature: .referralProgram),
                  let userWalletModel = userWalletRepository.selectedModel
            else {
                incomingActionManager.discardIncomingAction()
                return false
            }

            let input = ReferralInputModel(
                userWalletId: userWalletModel.userWalletId.value,
                supportedBlockchains: userWalletModel.config.supportedBlockchains,
                userTokensManager: userWalletModel.userTokensManager
            )

            coordinator.openDeepLink(.referral(input: input))
            return true
        }

        private func routeStakingAction(params: DeeplinkNavigationAction.Params) -> Bool {
            guard
                let coordinator,
                isFeatureSupported(feature: .staking),
                let userWalletModel = userWalletRepository.selectedModel,
                let tokenId = params.tokenId,
                let networkId = params.networkId,
                let walletModel = findWalletModel(in: userWalletModel, tokenId: tokenId, networkId: networkId, derivation: params.derivationPath),
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

            coordinator.openDeepLink(.staking(options: options))
            return true
        }
    }
}

// MARK: - Helpers

extension MainCoordinator.MainNavigationActionHandler {
    private func isFeatureSupported(feature: UserWalletFeature) -> Bool {
        guard let userWalletModel = userWalletRepository.selectedModel else {
            return false
        }

        let availibility = userWalletModel.config.getFeatureAvailability(feature)

        switch availibility {
        case .available:
            return true
        case .hidden, .disabled:
            return false
        }
    }

    private func isMatch(_ model: any WalletModel, tokenId: String, networkId: String, derivationPath: String?) -> Bool {
        let idMatch = model.tokenItem.id == tokenId
        let networkMatch = model.tokenItem.blockchain.networkId == networkId
        let derivationPathMatch = derivationPath.map { $0 == model.tokenItem.blockchainNetwork.derivationPath?.rawPath } ?? true
        return idMatch && networkMatch && derivationPathMatch
    }

    private func findWalletModel(
        in userWalletModel: any UserWalletModel,
        tokenId: String,
        networkId: String,
        derivation: String?
    ) -> (any WalletModel)? {
        let models = userWalletModel.walletModelsManager.walletModels
        
        if let derivation, derivation.isNotEmpty {
            return models.first { isMatch($0, tokenId: tokenId, networkId: networkId, derivationPath: derivation) }
        } else {
            let matchingModels = models.filter { isMatch($0, tokenId: tokenId, networkId: networkId, derivationPath: nil) }
            return matchingModels.first(where: { !$0.isCustom }) ?? matchingModels.first
        }
    }
}

// MARK: - IncomingActionResponder

extension MainCoordinator.MainNavigationActionHandler: IncomingActionResponder {
    func didReceiveIncomingAction(_ action: IncomingAction) -> Bool {
        routeIncomingAction(action)
    }
}
