//
//  SendingRestrictionsProvider.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import BlockchainSdk
import TangemMacro

protocol SendingRestrictionsProvider {
    var sendingRestrictionsPublisher: AnyPublisher<SendingRestrictions?, Never> { get }
}

// MARK: - SendingRestrictions

@CaseFlagable
enum SendingRestrictions: Hashable {
    case zeroWalletBalance
    case hasOnlyCachedBalance
    case cantSignLongTransactions
    case hasPendingWithdrawOrder
    case hasPendingTransaction(blockchain: Blockchain)
    case zeroFeeCurrencyBalance(configuration: NotEnoughFeeConfiguration)
    case blockchainUnreachable
    case blockchainLoading
    case oldCard
    case noAccount
}

// MARK: - TokenBalanceType + SendingRestrictions

extension TokenBalanceType {
    var sendingRestrictions: SendingRestrictions? {
        switch self {
        case .loading(.none):
            return .blockchainLoading
        case .empty(.noAccount):
            return .noAccount
        case .empty, .failure(.none):
            return .blockchainUnreachable
        case .loading(.some), .failure(.some):
            return .hasOnlyCachedBalance
        case .loaded(let value) where value == .zero:
            return .zeroWalletBalance
        case .loaded:
            return nil
        }
    }
}
