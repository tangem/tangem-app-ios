//
//  PolymarketDepositReceivingRestrictionsProvider.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

struct PolymarketDepositReceivingRestrictionsProvider: ReceivingRestrictionsProvider {
    @Injected(\.quotesRepository) private var quotesRepository: TokenQuotesRepository

    private let userWalletInfo: UserWalletInfo
    private let minimumDepositUSD: Decimal
    private let tokenItem: TokenItem

    init(userWalletInfo: UserWalletInfo, minimumDepositUSD: Decimal, tokenItem: TokenItem) {
        self.userWalletInfo = userWalletInfo
        self.minimumDepositUSD = minimumDepositUSD
        self.tokenItem = tokenItem
    }

    var isRestrictionKnown: Bool { true }

    func restriction(expectAmount: Decimal) async throws -> ReceivedRestriction? {
        if expectAmount > 0, let minimum = minimumReceiveAmount(), expectAmount < minimum {
            return .notEnoughReceivedAmount(minAmount: minimum, reason: .receivingMinimum)
        }

        guard userWalletInfo.backupState.isValid else {
            return .incompleteBackup(userWalletInfo)
        }

        return nil
    }
}

// MARK: - Private implementation

private extension PolymarketDepositReceivingRestrictionsProvider {
    func minimumReceiveAmount() -> Decimal? {
        guard let priceUsd = quotesRepository.quote(for: tokenItem)?.priceUsd, priceUsd > 0 else {
            return nil
        }

        return (minimumDepositUSD / priceUsd).rounded(scale: tokenItem.decimalCount, roundingMode: .up)
    }
}
