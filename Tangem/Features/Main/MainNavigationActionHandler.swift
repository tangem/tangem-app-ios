//
//  MainNavigationActionHandler.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import BlockchainSdk
import TangemVisa

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

        func resignIncomingActionsResponder() {
            incomingActionManager.resignFirstResponder(self)
        }

        // MARK: - Private Implementation

        private func routeIncomingAction(_ action: IncomingAction) -> Bool {
            guard coordinator != nil,
                  case .navigation(let navigationAction) = action,
                  !userWalletRepository.isLocked
            else {
                return false
            }

            switch navigationAction.destination {
            case .referral:
                return routeReferralAction(userWalletId: navigationAction.params.userWalletId)

            case .token:
                return routeTokenAction(params: navigationAction.params)

            case .buy:
                return routeBuyAction(userWalletId: navigationAction.params.userWalletId)

            case .sell:
                return routeSellAction(userWalletId: navigationAction.params.userWalletId)

            case .staking:
                return routeStakingAction(params: navigationAction.params)

            case .markets:
                return routeMarketAction()

            case .tokenChart:
                return routeTokenChartAction(params: navigationAction.params)

            case .link:
                return routeLinkAction(params: navigationAction.params)

            case .swap:
                return routeSwapAction(userWalletId: navigationAction.params.userWalletId)

            case .onboardVisa, .payApp:
                return routeOnboardVisaAction(
                    params: navigationAction.params,
                    deeplinkString: navigationAction.deeplinkString
                )

            case .promo:
                return routePromoAction(params: navigationAction.params)

            case .news:
                return routeNewsAction(params: navigationAction.params)
            }
        }

        private func routeNewsAction(params: DeeplinkNavigationAction.Params) -> Bool {
            guard let coordinator,
                  let idString = params.id,
                  let newsId = Int(idString)
            else {
                incomingActionManager.discardIncomingAction()
                return false
            }

            coordinator.openDeepLink(.newsDetails(newsId: newsId))
            return true
        }

        private func routePromoAction(params: DeeplinkNavigationAction.Params) -> Bool {
            guard let coordinator,
                  let promoCode = params.promoCode
            else {
                incomingActionManager.discardIncomingAction()
                return false
            }

            coordinator.openDeepLink(.promo(code: promoCode))
            return true
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

        private func routeSwapAction(userWalletId: String?) -> Bool {
            guard let userWalletModel = findUserWalletModel(userWalletModelId: userWalletId),
                  isFeatureSupported(feature: .swapping, userWalletModel: userWalletModel)
            else {
                incomingActionManager.discardIncomingAction()
                return false
            }

            coordinator?.openDeepLink(.swap(userWalletModel: userWalletModel))
            return true
        }

        private func routeSellAction(userWalletId: String?) -> Bool {
            guard let userWalletModel = findUserWalletModel(userWalletModelId: userWalletId),
                  isFeatureSupported(feature: .multiCurrency, userWalletModel: userWalletModel)
            else {
                incomingActionManager.discardIncomingAction()
                return false
            }

            coordinator?.openDeepLink(.sell(userWalletModel: userWalletModel))
            return true
        }

        private func routeBuyAction(userWalletId: String?) -> Bool {
            guard let userWalletModel = findUserWalletModel(userWalletModelId: userWalletId),
                  isFeatureSupported(feature: .multiCurrency, userWalletModel: userWalletModel)
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
                let userWalletModel = findUserWalletModel(userWalletModelId: params.userWalletId),
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
                // Trigger the update without awaiting to finished
                walletModel.startUpdateTask()
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
            case .incomeTransaction:
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

        private func routeReferralAction(userWalletId: String?) -> Bool {
            guard let coordinator,
                  let userWalletModel = findUserWalletModel(userWalletModelId: userWalletId),
                  isFeatureSupported(feature: .referralProgram, userWalletModel: userWalletModel)
            else {
                incomingActionManager.discardIncomingAction()
                return false
            }

            // accounts_fixes_needed_none
            let workMode: ReferralViewModel.WorkMode = FeatureProvider.isAvailable(.accounts) ?
                .accounts(userWalletModel.accountModelsManager) :
                .plainUserTokensManager(userWalletModel.userTokensManager)

            let input = ReferralInputModel(
                userWalletId: userWalletModel.userWalletId.value,
                supportedBlockchains: userWalletModel.config.supportedBlockchains,
                workMode: workMode,
                tokenIconInfoBuilder: TokenIconInfoBuilder()
            )

            coordinator.openDeepLink(.referral(input: input))
            return true
        }

        private func routeStakingAction(params: DeeplinkNavigationAction.Params) -> Bool {
            guard
                let coordinator,
                let userWalletModel = findUserWalletModel(userWalletModelId: params.userWalletId),
                isFeatureSupported(feature: .staking, userWalletModel: userWalletModel),
                let tokenId = params.tokenId,
                let networkId = params.networkId,
                let walletModel = findWalletModel(in: userWalletModel, tokenId: tokenId, networkId: networkId, derivation: params.derivationPath),
                TokenActionAvailabilityProvider(userWalletConfig: userWalletModel.config, walletModel: walletModel).isStakeAvailable,
                let stakingManager = walletModel.stakingManager
            else {
                incomingActionManager.discardIncomingAction()
                return false
            }

            let input = SendInput(userWalletInfo: userWalletModel.userWalletInfo, walletModel: walletModel)
            let options = StakingDetailsCoordinator.Options(sendInput: input, manager: stakingManager)
            coordinator.openDeepLink(.staking(options: options))
            return true
        }

        private func routeOnboardVisaAction(
            params: DeeplinkNavigationAction.Params,
            deeplinkString: String
        ) -> Bool {
            guard FeatureProvider.isAvailable(.visa),
                  let coordinator
            else {
                incomingActionManager.discardIncomingAction()
                return false
            }

            coordinator.openDeepLink(
                .onboardVisa(
                    deeplinkString: deeplinkString
                )
            )
            return true
        }
    }
}

// MARK: - Helpers

extension MainCoordinator.MainNavigationActionHandler {
    private func isFeatureSupported(feature: UserWalletFeature, userWalletModel: any UserWalletModel) -> Bool {
        switch userWalletModel.config.getFeatureAvailability(feature) {
        case .available:
            return true
        case .disabled, .hidden:
            return false
        }
    }

    private func findUserWalletModel(userWalletModelId: String?) -> (any UserWalletModel)? {
        guard let userWalletModelId else {
            return userWalletRepository.selectedModel
        }

        return userWalletRepository.models.first { $0.userWalletId.stringValue == userWalletModelId }
    }

    private func findWalletModel(
        in userWalletModel: any UserWalletModel,
        tokenId: String,
        networkId: String,
        derivation: String?
    ) -> (any WalletModel)? {
        var walletModels = AccountsFeatureAwareWalletModelsResolver.walletModels(for: userWalletModel)

        if FeatureProvider.isAvailable(.accounts) {
            // If derivation is missing, prefer main account's wallet model - this is why we sort them here
            walletModels.sort { first, second in
                let isFirstMainAccount = first.account?.isMainAccount ?? false
                let isSecondMainAccount = second.account?.isMainAccount ?? false
                return isFirstMainAccount && !isSecondMainAccount
            }
        }

        return findWalletModel(
            in: walletModels,
            tokenId: tokenId,
            networkId: networkId,
            derivation: derivation
        )
    }

    private func findWalletModel(
        in walletModels: [any WalletModel],
        tokenId: String,
        networkId: String,
        derivation: String?
    ) -> (any WalletModel)? {
        // Strict match if derivation is provided
        if let derivation = derivation?.nilIfEmpty {
            return walletModels.first { isMatch($0, tokenId: tokenId, networkId: networkId, derivationPath: derivation) }
        }

        // Loose match with fallback if derivation is not provided
        let matchingModels = walletModels.filter { isMatch($0, tokenId: tokenId, networkId: networkId, derivationPath: nil) }
        return matchingModels.first(where: { !$0.isCustom }) ?? matchingModels.first
    }

    private func isMatch(_ model: any WalletModel, tokenId: String, networkId: String, derivationPath: String?) -> Bool {
        let idMatch = model.tokenItem.id == tokenId
        let networkMatch = model.tokenItem.blockchain.networkId == networkId
        let derivationPathMatch = derivationPath.map { $0 == model.tokenItem.blockchainNetwork.derivationPath?.rawPath } ?? true
        return idMatch && networkMatch && derivationPathMatch
    }
}

// MARK: - IncomingActionResponder

extension MainCoordinator.MainNavigationActionHandler: IncomingActionResponder {
    func didReceiveIncomingAction(_ action: IncomingAction) -> Bool {
        routeIncomingAction(action)
    }
}
