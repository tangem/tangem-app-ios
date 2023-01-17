//
//  TotalBalanceSupportData.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation

struct TotalBalanceCardSupportInfo {
    let cardBatchId: String
    let cardNumberHash: String
    let embeddedBlockchainCurrencySymbol: String?

    init(cardBatchId: String, cardNumber: String, embeddedBlockchainCurrencySymbol: String?) {
        self.cardBatchId = cardBatchId
        self.cardNumberHash = cardNumber.sha256Hash.hexString
        self.embeddedBlockchainCurrencySymbol = embeddedBlockchainCurrencySymbol
    }
}

class TotalBalanceAnalyticsService {
    let totalBalanceCardSupportInfo: TotalBalanceCardSupportInfo
    private let userDefaults = UserDefaults.standard

    private var cardBalanceInfoWasSaved: Bool {
        userDefaults.data(forKey: totalBalanceCardSupportInfo.cardNumberHash) != nil
    }
    
    private var basicCurrency: String {
        return totalBalanceCardSupportInfo.embeddedBlockchainCurrencySymbol ?? Analytics.ParameterValue.multicurrency.rawValue
    }

    init(totalBalanceCardSupportInfo: TotalBalanceCardSupportInfo) {
        self.totalBalanceCardSupportInfo = totalBalanceCardSupportInfo
    }

    func sendFirstLoadBalanceEventForCard(tokenItemViewModels: [TokenItemViewModel], balance: Decimal) {
        let params: [Analytics.ParameterKey: String] = [
            .state: Analytics.ParameterValue.state(for: balance).rawValue,
            .basicCurrency: basicCurrency,
            .batchId: totalBalanceCardSupportInfo.cardBatchId,
        ]
            
        Analytics.log(.signedIn, params: params)
    }

    func sendToppedUpEventIfNeeded(tokenItemViewModels: [TokenItemViewModel], balance: Decimal) {
        guard balance > 0 else {
            if !cardBalanceInfoWasSaved {
                let encodedData = try? JSONEncoder().encode(Decimal(0))
                userDefaults.set(encodedData, forKey: totalBalanceCardSupportInfo.cardNumberHash)
            }
            return
        }

        if let data = userDefaults.data(forKey: totalBalanceCardSupportInfo.cardNumberHash),
           let previousBalance = try? JSONDecoder().decode(Decimal.self, from: data),
           previousBalance == 0
        {
            Analytics.log(.toppedUp, params: [.basicCurrency: basicCurrency])
            let encodeToData = try? JSONEncoder().encode(balance)
            userDefaults.set(encodeToData, forKey: totalBalanceCardSupportInfo.cardNumberHash)
        }
    }
}
