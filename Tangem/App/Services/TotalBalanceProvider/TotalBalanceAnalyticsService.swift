//
//  TotalBalanceSupportData.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation

class TotalBalanceAnalyticsService {
    let totalBalanceCardSupportInfo: TotalBalanceCardSupportInfo
    private let userDefaults = UserDefaults.standard

    private var cardBalanceInfoWasSaved: Bool {
        userDefaults.data(forKey: totalBalanceCardSupportInfo.cardIdentifier) != nil
    }

    private var basicCurrency: String {
        return totalBalanceCardSupportInfo.embeddedBlockchainCurrencySymbol ?? Analytics.ParameterValue.multicurrency.rawValue
    }

    init(totalBalanceCardSupportInfo: TotalBalanceCardSupportInfo) {
        self.totalBalanceCardSupportInfo = totalBalanceCardSupportInfo
    }

    func sendFirstLoadBalanceEventForCard(balance: Decimal) {
        Analytics.logCardSignIn(
            balance: balance,
            basicCurrency: basicCurrency,
            batchId: totalBalanceCardSupportInfo.cardBatchId,
            cardIdentifier: totalBalanceCardSupportInfo.cardIdentifier
        )
    }

    func sendToppedUpEventIfNeeded(balance: Decimal) {
        guard balance > 0 else {
            if !cardBalanceInfoWasSaved {
                let encodedData = try? JSONEncoder().encode(Decimal(0))
                userDefaults.set(encodedData, forKey: totalBalanceCardSupportInfo.cardIdentifier)
            }
            return
        }

        if let data = userDefaults.data(forKey: totalBalanceCardSupportInfo.cardIdentifier),
           let previousBalance = try? JSONDecoder().decode(Decimal.self, from: data),
           previousBalance == 0 {
            Analytics.log(.toppedUp, params: [.basicCurrency: basicCurrency])
            let encodeToData = try? JSONEncoder().encode(balance)
            userDefaults.set(encodeToData, forKey: totalBalanceCardSupportInfo.cardIdentifier)
        }
    }
}
