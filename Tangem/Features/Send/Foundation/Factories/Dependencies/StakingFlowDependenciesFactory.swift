//
//   StakingFlowDependenciesFactory.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemStaking
import TangemLocalization

/// Sharing between Staking / Restaking / Unstaking / StakingSingleAction
protocol StakingFlowDependenciesFactory: SendGenericFlowBaseDependenciesFactory {
    var actionType: StakingAction.ActionType { get }

    func maxAmount() -> Decimal
    func walletHeaderText() -> String
    func formattedBalance() -> String
}

// MARK: - Default

extension StakingFlowDependenciesFactory {
    func maxAmount() -> Decimal {
        walletModelBalancesProvider.availableBalanceProvider.balanceType.value ?? 0
    }

    func walletHeaderText() -> String {
        userWalletInfo.name
    }

    func formattedBalance() -> String {
        Localization.commonCryptoFiatFormat(
            walletModelBalancesProvider.availableBalanceProvider.formattedBalanceType.value,
            walletModelBalancesProvider.fiatAvailableBalanceProvider.formattedBalanceType.value
        )
    }
}

// MARK: - Shared dependencies

extension StakingFlowDependenciesFactory {
    func makeCurrencyPickerData() -> SendCurrencyPickerData {
        SendCurrencyPickerData(
            cryptoIconURL: tokenIconInfo.imageURL,
            cryptoCurrencyCode: tokenItem.currencySymbol,
            fiatIconURL: makeFiatItem().iconURL,
            fiatCurrencyCode: AppSettings.shared.selectedCurrencyCode,
            disabled: !possibleToConvertToFiat()
        )
    }

    func makeSendAmountViewModelSettings() -> SendAmountViewModel.Settings {
        SendAmountViewModel.Settings(
            walletHeaderText: walletHeaderText(),
            tokenItem: tokenItem,
            tokenIconInfo: tokenIconInfo,
            balanceFormatted: formattedBalance(),
            currencyPickerData: makeCurrencyPickerData()
        )
    }

    func makeStakingTransactionDispatcher(
        stakingManger: some StakingManager,
        analyticsLogger: any StakingAnalyticsLogger
    ) -> TransactionDispatcher {
        transactionDispatcherFactory.makeStakingTransactionDispatcher(
            stakingManger: stakingManger,
            analyticsLogger: analyticsLogger
        )
    }

    func makeStakingNotificationManager() -> StakingNotificationManager {
        CommonStakingNotificationManager(tokenItem: tokenItem, feeTokenItem: feeTokenItem)
    }

    func makeStakingAlertBuilder() -> SendAlertBuilder {
        StakingSendAlertBuilder()
    }

    func makeStakingBaseDataBuilder(input: StakingBaseDataBuilderInput) -> StakingBaseDataBuilder {
        baseDataBuilderFactory.makeStakingBaseDataBuilder(input: input)
    }

    func makeStakingFeeIncludedCalculator() -> FeeIncludedCalculator {
        StakingFeeIncludedCalculator(tokenItem: tokenItem, validator: walletModelDependenciesProvider.transactionValidator)
    }

    func makeStakingTransactionSummaryDescriptionBuilder() -> StakingTransactionSummaryDescriptionBuilder {
        CommonStakingTransactionSummaryDescriptionBuilder(tokenItem: tokenItem)
    }

    func makeStakingSendAnalyticsLogger() -> StakingSendAnalyticsLogger {
        CommonStakingSendAnalyticsLogger(
            tokenItem: tokenItem,
            actionType: sendFlowActionType()
        )
    }

    func makeStakingSummaryTitleProvider() -> SendSummaryTitleProvider {
        StakingSendSummaryTitleProvider(actionType: sendFlowActionType(), tokenItem: tokenItem, walletName: userWalletInfo.name)
    }

    func sendFlowActionType() -> SendFlowActionType {
        switch actionType {
        case .stake, .pending(.stake): .stake
        case .unstake: .unstake
        case .pending(.claimRewards): .claimRewards
        case .pending(.withdraw): .withdraw
        case .pending(.restakeRewards): .restakeRewards
        case .pending(.voteLocked): .voteLocked
        case .pending(.unlockLocked): .unlockLocked
        case .pending(.restake): .restake
        case .pending(.claimUnstaked): .claimUnstaked
        }
    }
}
