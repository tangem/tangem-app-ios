//
//  DefaultTokenItemInfoProvider.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemStaking

class DefaultTokenItemInfoProvider {
    private let walletModel: any WalletModel

    private let balanceProvider: TokenBalanceProvider
    private let fiatBalanceProvider: TokenBalanceProvider
    private let yieldModuleManager: YieldModuleManager?

    init(walletModel: any WalletModel) {
        self.walletModel = walletModel

        balanceProvider = walletModel.totalTokenBalanceProvider
        fiatBalanceProvider = walletModel.fiatTotalTokenBalanceProvider
        yieldModuleManager = walletModel.yieldModuleManager
//        AppLogger.debug("[YieldModule] DefaultTokenItemInfoProvider init for \(walletModel.tokenItem.name), yieldModuleManager=\(yieldModuleManager != nil ? "exists" : "nil")")
    }
}

extension DefaultTokenItemInfoProvider: TokenItemInfoProvider {
    var id: WalletModelId.ID { walletModel.id.id }

    var tokenItem: TokenItem { walletModel.tokenItem }

    var quote: WalletModelRate {
        walletModel.rate
    }

    var balance: TokenBalanceType {
        balanceProvider.balanceType
    }

    var balanceType: FormattedTokenBalanceType {
        balanceProvider.formattedBalanceType
    }

    var fiatBalanceType: FormattedTokenBalanceType {
        fiatBalanceProvider.formattedBalanceType
    }

    var quotePublisher: AnyPublisher<WalletModelRate, Never> {
        walletModel.ratePublisher.eraseToAnyPublisher()
    }

    var balancePublisher: AnyPublisher<TokenBalanceType, Never> {
        balanceProvider.balanceTypePublisher
    }

    var balanceTypePublisher: AnyPublisher<FormattedTokenBalanceType, Never> {
        balanceProvider.formattedBalanceTypePublisher
    }

    var fiatBalanceTypePublisher: AnyPublisher<FormattedTokenBalanceType, Never> {
        fiatBalanceProvider.formattedBalanceTypePublisher
    }

    var actionsUpdatePublisher: AnyPublisher<Void, Never> { walletModel.actionsUpdatePublisher }

    var hasPendingTransactions: AnyPublisher<Bool, Never> {
        walletModel
            .pendingTransactionPublisher
            .map { !$0.isEmpty }
            .eraseToAnyPublisher()
    }

    var leadingBadgePublisher: AnyPublisher<TokenItemViewModel.LeadingBadge?, Never> {
        Publishers.CombineLatest3(
            hasPendingTransactions,
            yieldModuleStatePublisher,
            walletModel.stakingManagerStatePublisher
        )
        .map { hasPendingTransactions, yieldModuleState, stakingManagerState -> TokenItemViewModel.LeadingBadge? in
            guard !hasPendingTransactions else {
                return .pendingTransaction
            }

            if let yieldModuleState, let marketInfo = yieldModuleState.marketInfo {
                return LeadingBadgeMapper.mapRewards(marketInfo: marketInfo, state: yieldModuleState.state)
            } else {
                return LeadingBadgeMapper.mapRewards(stakingManagerState: stakingManagerState)
            }
        }
        .eraseToAnyPublisher()
    }

    var trailingBadgePublisher: AnyPublisher<TokenItemViewModel.TrailingBadge?, Never> {
        yieldModuleStatePublisher
            .filter { !($0?.state.isLoading ?? false) }
            .map { state -> TokenItemViewModel.TrailingBadge? in
                guard case .active(let supply) = state?.state else { return nil }
                return supply.isAllowancePermissionRequired ? .isApproveNeeded : nil
            }
            .eraseToAnyPublisher()
    }
}

private extension DefaultTokenItemInfoProvider {
    var yieldModuleStatePublisher: AnyPublisher<YieldModuleManagerStateInfo?, Never> {
        if let manager = yieldModuleManager {
//            AppLogger.debug("[YieldModule] \(walletModel.tokenItem.name) yieldModuleStatePublisher accessed, manager exists")
            return manager.statePublisher
//                .handleEvents(receiveOutput: { stateInfo in
//                    AppLogger.debug("[YieldModule] \(self.walletModel.tokenItem.name) statePublisher emitted: state=\(String(describing: stateInfo?.state)), marketInfo=\(stateInfo?.marketInfo != nil ? "exists (apy=\(stateInfo?.marketInfo?.apy ?? 0), isActive=\(stateInfo?.marketInfo?.isActive ?? false))" : "nil")")
//                })
                .filter { stateInfo in
                    switch stateInfo?.state {
                    case .none:
                        return false
                    case .processing, .loading(.none):
                        return false
                    case .loading(.some):
                        return true
                    case .active, .notActive, .failedToLoad, .disabled:
                        return true
                    }
                }
                .eraseToAnyPublisher()
        } else {
//            AppLogger.debug("[YieldModule] \(walletModel.tokenItem.name) yieldModuleStatePublisher accessed, manager is nil")
            return Just(.none).eraseToAnyPublisher()
        }
    }
}

extension DefaultTokenItemInfoProvider: Equatable {
    static func == (lhs: DefaultTokenItemInfoProvider, rhs: DefaultTokenItemInfoProvider) -> Bool {
        lhs.id == rhs.id
    }
}

private enum LeadingBadgeMapper {
    typealias RewardsInfo = TokenItemViewModel.RewardsInfo
    typealias LeadingBadge = TokenItemViewModel.LeadingBadge

    static func mapRewards(stakingManagerState: StakingManagerState) -> LeadingBadge? {
        guard let apy = stakingManagerState.apy,
              let rewardType = stakingManagerState.rewardType else {
            return nil
        }

        let formattedRewardValue = PercentFormatter().format(apy, option: .staking)

        return .rewards(
            RewardsInfo(
                type: rewardType,
                rewardValue: formattedRewardValue,
                isActive: stakingManagerState.isActive,
                isUpdating: stakingManagerState.isLoading
            )
        )
    }

    static func mapRewards(marketInfo: YieldModuleMarketInfo, state: YieldModuleManagerState) -> LeadingBadge? {
        let formattedRewardValue = PercentFormatter().format(marketInfo.apy, option: .staking)

        let actualState: YieldModuleManagerState = switch state {
        case .failedToLoad(_, .some(let cachedState)):
            cachedState
        default:
            state
        }

        let rewardsInfo: RewardsInfo? = switch actualState {
        case .active:
            RewardsInfo(
                type: .apy,
                rewardValue: formattedRewardValue,
                isActive: true,
                isUpdating: false
            )

        case .notActive:
            if marketInfo.isActive {
                RewardsInfo(type: .apy, rewardValue: formattedRewardValue, isActive: false, isUpdating: false)
            } else {
                nil
            }

        case .loading(let cached?):
            RewardsInfo(
                type: .apy,
                rewardValue: formattedRewardValue,
                isActive: cached.isEffectivelyActive,
                isUpdating: true
            )

        case .disabled, .failedToLoad, .processing, .loading(cachedState: nil):
            nil
        }

        return rewardsInfo.flatMap { .rewards($0) }
    }
}
