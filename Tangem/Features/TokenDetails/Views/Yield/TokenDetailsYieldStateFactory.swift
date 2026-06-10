//
//  TokenDetailsYieldStateFactory.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemUI
import TangemLocalization

final class TokenDetailsYieldStateFactory {
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

    func make(info: YieldModuleManagerStateInfo) -> TokenDetailsYieldState {
        guard
            let manager = walletModel.yieldModuleManager,
            let factory = factoryBuilder(manager)
        else {
            return .unavailable
        }
        return make(info: info, factory: factory)
    }
}

private extension TokenDetailsYieldStateFactory {
    func make(
        info: YieldModuleManagerStateInfo,
        factory: YieldModuleFlowFactory
    ) -> TokenDetailsYieldState {
        switch info.state {
        case .loading:
            return .loading

        case .notActive(let promoStatus):
            return makeAvailableYieldState(
                info: info,
                promoStatus: promoStatus,
                factory: factory
            )

        case .processing(let action):
            return makeProcessingYieldState(action: action)

        case .active(let supplyInfo, _):
            return makeActiveYieldState(
                info: supplyInfo,
                apy: info.marketInfo?.apy,
                factory: factory
            )

        case .failedToLoad(_, let cachedState):
            if let cachedState {
                let stateInfo = YieldModuleManagerStateInfo(
                    marketInfo: info.marketInfo,
                    state: cachedState
                )
                return make(info: stateInfo, factory: factory)
            } else {
                return makeAvailableYieldState(
                    info: info,
                    promoStatus: .undefined,
                    factory: factory
                )
            }

        case .disabled:
            return .unavailable
        }
    }

    func makeAvailableYieldState(
        info: YieldModuleManagerStateInfo,
        promoStatus: YieldPromoStatus,
        factory: YieldModuleFlowFactory
    ) -> TokenDetailsYieldState {
        if promoStatus == .notStarted {
            return makePromoAvailableYieldState(
                info: info,
                factory: factory
            )
        }

        guard let marketInfo = info.marketInfo else {
            return .unavailable
        }

        let apy = marketInfo.apy
        let formattedApy = formattedApy(apy)

        let title = "\(Localization.commonYieldMode)"
            + " \(AppConstants.dotSign) \(formattedApy)"
            + " \(Localization.yieldModuleTokenDetailsEarnNotificationApy)"

        let action = TokenDetailsYieldState.Action(
            title: Localization.commonMore,
            closure: { [weak self] in
                self?.coordinator?.openYieldModulePromoView(
                    apy: apy,
                    isApyBoostPromo: false,
                    factory: factory
                )
            }
        )

        let item = TokenDetailsYieldState.AvailableItem(
            title: title,
            description: Localization.yieldModuleTokenDetailsEarnNotificationDescription,
            action: action
        )

        return .available(item: item)
    }

    func makePromoAvailableYieldState(
        info: YieldModuleManagerStateInfo,
        factory: YieldModuleFlowFactory
    ) -> TokenDetailsYieldState {
        guard let marketInfo = info.marketInfo else {
            return .unavailable
        }

        let originalApy = marketInfo.apy
        let originalFormattedApy = formattedApy(originalApy)

        let promoMultiplier: Decimal = 3
        let promoApy = originalApy * promoMultiplier
        let promoFormattedApy = formattedApy(promoApy)

        var heading = AttributedString(Localization.yieldApyBoostBannerTitle)
        heading.font = .Tangem.Body16.medium
        heading.foregroundColor = .Tangem.Text.Neutral.primary

        let apyLineText = "\(Localization.yieldModuleTokenDetailsEarnNotificationApy) \(originalFormattedApy)"
            + " x\(promoMultiplier)"
            + " → \(promoFormattedApy)"

        var apyLine = AttributedString(apyLineText)
        apyLine.font = .Tangem.Body16.medium
        apyLine.foregroundColor = .Tangem.Text.Neutral.primary

        if let originalApyRange = apyLine.range(of: originalFormattedApy) {
            apyLine[originalApyRange].strikethroughStyle = .single
        }

        let attributedTitle = heading + AttributedString("\n") + apyLine

        let learnAction = TokenDetailsYieldState.Action(
            title: Localization.commonLearnMore,
            closure: { [weak self] in
                self?.coordinator?.openYieldApyBoostStory(apy: originalApy, factory: factory)
            }
        )

        let activateAction = TokenDetailsYieldState.Action(
            title: Localization.commonActivate,
            closure: { [weak self] in
                self?.coordinator?.openYieldModulePromoView(
                    apy: originalApy,
                    isApyBoostPromo: true,
                    factory: factory
                )
            }
        )

        let item = TokenDetailsYieldState.PromoAvailableItem(
            title: attributedTitle,
            description: Localization.yieldApyBoostBannerSubtitle,
            learnAction: learnAction,
            activateAction: activateAction
        )

        return .promoAvailable(item: item)
    }

    func makeProcessingYieldState(action: YieldModuleManagerState.ProcessingAction) -> TokenDetailsYieldState {
        let type: TokenDetailsYieldState.ProcessingType
        let description: String

        switch action {
        case .enter:
            type = .enabling
            description = Localization.commonEnabling
        case .exit:
            type = .disabling
            description = Localization.commonDisabling
        }

        let item = TokenDetailsYieldState.ProcessingItem(
            type: type,
            title: Localization.commonYieldMode,
            description: description
        )

        return .processing(item: item)
    }

    func makeActiveYieldState(
        info: YieldSupplyInfo,
        apy: Decimal?,
        factory: YieldModuleFlowFactory
    ) -> TokenDetailsYieldState {
        let description = apy.map {
            let percentOption = PercentFormatter.Option(fractionDigits: .two, prefix: .empty, suffix: .empty)
            let percent = PercentFormatter().format($0, option: percentOption)
            return Localization.yieldModuleAverageApy(percent)
        } ?? .empty

        let action = TokenDetailsYieldState.Action(
            title: Localization.detailsTitle,
            closure: { [weak self] in
                self?.coordinator?.openYieldModuleActiveInfo(factory: factory)
            }
        )

        let item = TokenDetailsYieldState.ActiveItem(
            title: Localization.yieldModuleTransactionEnter,
            description: description,
            badgeType: { [weak self] in
                await self?.yieldActiveBadgeType(info: info, factory: factory) ?? .none
            },
            action: action
        )

        return .active(item: item)
    }

    func yieldActiveBadgeType(
        info: YieldSupplyInfo,
        factory: YieldModuleFlowFactory
    ) async -> TokenDetailsYieldState.ActiveBadgeType {
        if info.isAllowancePermissionRequired {
            return .attention
        }

        let interactor = factory.makeYieldManagerInteractor()

        guard let params = try? await interactor.getCurrentFeeParameters() else {
            return .none
        }

        let feeConverter = YieldModuleFeeFormatter(
            feeCurrency: walletModel.feeTokenItem,
            token: walletModel.tokenItem
        )
        let dustFilter = YieldModuleDustFilter(feeConverter: feeConverter)

        let minimalTopupAmountInFiat = try? await interactor.getMinAmount(feeParameters: params)
        let undepositedAmount = await dustFilter.filterUndepositedAmount(
            info.nonYieldModuleBalanceValue,
            minimalTopupAmountInFiat: minimalTopupAmountInFiat
        )

        return undepositedAmount != nil ? .warning : .none
    }

    func formattedApy(_ apy: Decimal) -> String {
        PercentFormatter().format(apy, option: .yield)
    }
}
