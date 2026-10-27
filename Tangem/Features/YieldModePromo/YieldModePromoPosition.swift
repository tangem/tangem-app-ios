//
//  YieldModePromoPosition.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

struct YieldModePromoPosition: Equatable {
    let chainId: Int?
    let contractAddress: String?
    let tokenSymbol: String
    let blockchainName: String
    let balance: Balance
    let fiatBalance: Balance
    let yieldState: YieldState
}

extension YieldModePromoPosition {
    enum Balance: Equatable {
        case loading
        case missingDerivation
        case failed
        case loaded(Decimal)
    }

    enum YieldState: Equatable {
        case loading
        case awaitingMarkets
        case disabled
        case failed
        case notActive
        case active
    }
}

// MARK: - WalletModel

extension YieldModePromoPosition {
    init?(walletModel: any WalletModel) {
        guard let yieldModuleManager = walletModel.yieldModuleManager else {
            return nil
        }

        let tokenItem = walletModel.tokenItem

        self.init(
            chainId: tokenItem.blockchain.chainId,
            contractAddress: tokenItem.contractAddress,
            tokenSymbol: tokenItem.currencySymbol,
            blockchainName: tokenItem.networkName,
            balance: Balance(walletModel.availableBalanceProvider.balanceType),
            fiatBalance: Balance(walletModel.fiatAvailableBalanceProvider.balanceType),
            yieldState: YieldState(yieldModuleManager.state)
        )
    }
}

extension YieldModePromoPosition.Balance {
    init(_ balanceType: TokenBalanceType) {
        switch balanceType {
        case .loaded(let value):
            self = .loaded(value)
        case .empty(.noAccount):
            self = .loaded(.zero)
        case .empty(.noData), .loading:
            self = .loading
        case .empty(.noDerivation):
            self = .missingDerivation
        case .empty(.custom), .failure:
            self = .failed
        }
    }
}

extension YieldModePromoPosition.YieldState {
    init(_ stateInfo: YieldModuleManagerStateInfo?) {
        guard let stateInfo else {
            self = .loading
            return
        }

        if stateInfo.state.isEffectivelyActive {
            self = .active
            return
        }

        switch stateInfo.state {
        case .notActive:
            self = .notActive
        case .active, .processing:
            self = .active
        case .disabled:
            self = stateInfo.marketInfo == nil ? .awaitingMarkets : .disabled
        case .failedToLoad:
            self = .failed
        case .loading:
            self = .loading
        }
    }
}
