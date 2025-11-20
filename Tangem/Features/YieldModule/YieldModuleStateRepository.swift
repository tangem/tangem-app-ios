//
//  YieldModuleStateRepository.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk
import TangemFoundation

protocol YieldModuleStateRepository {
    func storeState(_ state: YieldModuleManagerState)
    func state() -> YieldModuleManagerState?
    func clearState()
}

final class CommonYieldModuleStateRepository {
    private let storage = CachesDirectoryStorage(file: .cachedYieldModuleState)

    let walletModelId: WalletModelId
    let userWalletId: UserWalletId
    let token: Token

    init(walletModelId: WalletModelId, userWalletId: UserWalletId, token: Token) {
        self.walletModelId = walletModelId
        self.userWalletId = userWalletId
        self.token = token
    }
}

extension CommonYieldModuleStateRepository: YieldModuleStateRepository {
    func storeState(_ state: YieldModuleManagerState) {
        let stateToCache: CachedYieldModuleState

        switch state {
        case .disabled, .loading, .failedToLoad: return
        case .notActive:
            stateToCache = .notActive
        case .processing(let action):
            stateToCache = .processing(isEnter: action == .enter)
        case .active(let yieldSupplyInfo):
            stateToCache = .active(
                supply: CachedYieldSupplyInfo(
                    yieldContractAddress: yieldSupplyInfo.yieldContractAddress,
                    balanceValue: yieldSupplyInfo.balance.value,
                    token: token,
                    blockchain: walletModelId.tokenItem.blockchain,
                    isAllowancePermissionRequired: yieldSupplyInfo.isAllowancePermissionRequired,
                    yieldModuleBalanceValue: yieldSupplyInfo.yieldModuleBalanceValue
                )
            )
        }

        updateUserWalletState { stateForUserWallet in
            stateForUserWallet.updateValue(stateToCache, forKey: walletModelId.id)
        }
    }

    func state() -> YieldModuleManagerState? {
        let currentState = getCurrentState()

        let cachedState: CachedYieldModuleState? = currentState[userWalletId.stringValue]?[walletModelId.id]

        return cachedState.flatMap { cachedState in
            switch cachedState {
            case .notActive:
                return .notActive
            case .processing(let isEnter):
                return .processing(action: isEnter ? .enter : .exit)
            case .active(let supply):
                return .active(
                    YieldSupplyInfo(
                        yieldContractAddress: supply.yieldContractAddress,
                        balance: Amount(
                            with: supply.blockchain,
                            type: .token(value: supply.token),
                            value: supply.balanceValue
                        ),
                        isAllowancePermissionRequired: supply.isAllowancePermissionRequired,
                        yieldModuleBalanceValue: supply.yieldModuleBalanceValue
                    )
                )
            }
        }
    }

    func clearState() {
        updateUserWalletState { stateForUserWallet in
            stateForUserWallet.removeValue(forKey: walletModelId.id)
        }
    }

    private func updateUserWalletState(_ updateBlock: (inout [String: CachedYieldModuleState]) -> Void) {
        var currentState = getCurrentState()
        var stateForUserWallet = currentState[userWalletId.stringValue, default: [:]]

        updateBlock(&stateForUserWallet)

        currentState.updateValue(stateForUserWallet, forKey: userWalletId.stringValue)
        try? storage.storeAndWait(value: currentState)
    }

    private func getCurrentState() -> [String: [String: CachedYieldModuleState]] {
        (try? storage.value()) ?? .init()
    }
}

enum CachedYieldModuleState: Codable {
    case notActive
    case processing(isEnter: Bool)
    case active(supply: CachedYieldSupplyInfo)
}

struct CachedYieldSupplyInfo: Codable {
    let yieldContractAddress: String
    let balanceValue: Decimal
    let token: Token
    let blockchain: Blockchain
    let isAllowancePermissionRequired: Bool
    let yieldModuleBalanceValue: Decimal
}
