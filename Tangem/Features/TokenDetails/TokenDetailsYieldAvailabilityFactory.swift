//
//  TokenDetailsYieldAvailabilityFactory.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

final class TokenDetailsYieldAvailabilityFactory {
    private let walletModel: any WalletModel
    private weak var coordinator: (any TokenDetailsRoutable)?
    private let factoryBuilder: (YieldModuleManager) -> YieldModuleFlowFactory?

    init(
        walletModel: any WalletModel,
        coordinator: (any TokenDetailsRoutable)?,
        factoryBuilder: @escaping (YieldModuleManager) -> YieldModuleFlowFactory?
    ) {
        self.walletModel = walletModel
        self.coordinator = coordinator
        self.factoryBuilder = factoryBuilder
    }

    func make(state: YieldModuleManagerState, marketInfo: YieldModuleMarketInfo?) -> YieldModuleAvailability {
        guard let manager = walletModel.yieldModuleManager,
              let factory = factoryBuilder(manager)
        else {
            return .notApplicable
        }
        return resolve(state: state, marketInfo: marketInfo, factory: factory)
    }
}

// MARK: - Resolution

private extension TokenDetailsYieldAvailabilityFactory {
    func resolve(
        state: YieldModuleManagerState,
        marketInfo: YieldModuleMarketInfo?,
        factory: YieldModuleFlowFactory
    ) -> YieldModuleAvailability {
        switch state {
        case .active(let info, _):
            return makeActiveAvailability(info: info, marketInfo: marketInfo, factory: factory)

        case .notActive(let promoStatus):
            return makeEligibleAvailability(promoStatus: promoStatus, marketInfo: marketInfo, factory: factory)

        case .processing(let action):
            let state: YieldStatusViewModel.State = action == .enter ? .loading : .closing
            let vm = factory.makeYieldStatusViewModel(state: state, navigationAction: {})
            return action == .enter ? .enter(vm) : .exit(vm)

        case .disabled:
            return .notApplicable

        case .loading:
            AppLogger.warning("Loading state should not be passed here to avoid blinking on UI")
            return .notApplicable

        case .failedToLoad(_, .some(let cachedState)):
            return resolve(state: cachedState, marketInfo: marketInfo, factory: factory)

        case .failedToLoad:
            return makeEligibleAvailability(promoStatus: .undefined, marketInfo: marketInfo, factory: factory)
        }
    }

    func makeActiveAvailability(
        info: YieldSupplyInfo,
        marketInfo: YieldModuleMarketInfo?,
        factory: YieldModuleFlowFactory
    ) -> YieldModuleAvailability {
        let state: YieldStatusViewModel.State = .active(
            isApproveRequired: info.isAllowancePermissionRequired,
            undepositedAmount: info.nonYieldModuleBalanceValue,
            apy: marketInfo?.apy
        )

        let vm = factory.makeYieldStatusViewModel(state: state) { [weak self] in
            self?.coordinator?.openYieldModuleActiveInfo(factory: factory)
        }

        if info.isAllowancePermissionRequired {
            Analytics.log(
                event: .earningNoticeApproveNeeded,
                params: [.token: walletModel.tokenItem.currencySymbol, .blockchain: walletModel.tokenItem.blockchain.displayName]
            )
        }

        return .active(vm)
    }

    func makeEligibleAvailability(
        promoStatus: YieldPromoStatus,
        marketInfo: YieldModuleMarketInfo?,
        factory: YieldModuleFlowFactory
    ) -> YieldModuleAvailability {
        guard let apy = marketInfo?.apy else {
            return .notApplicable
        }

        let isApyBoostPromo = promoStatus == .notStarted
        let style: YieldAvailableNotificationViewModel.Style = isApyBoostPromo ? .promo : .standard

        let learnMoreAction: (Decimal) -> Void = { [weak self] apy in
            if isApyBoostPromo {
                self?.coordinator?.openYieldApyBoostStory(apy: apy, factory: factory)
            } else {
                self?.coordinator?.openYieldModulePromoView(apy: apy, isApyBoostPromo: false, factory: factory)
            }
        }

        let activateAction: ((Decimal) -> Void)? = isApyBoostPromo
            ? { [weak self] apy in
                self?.coordinator?.openYieldModulePromoView(apy: apy, isApyBoostPromo: true, factory: factory)
            }
            : nil

        let vm = factory.makeYieldAvailableNotificationViewModel(
            apy: apy,
            style: style,
            onLearnMoreTap: learnMoreAction,
            onActivateTap: activateAction
        )

        return .eligible(vm)
    }
}
