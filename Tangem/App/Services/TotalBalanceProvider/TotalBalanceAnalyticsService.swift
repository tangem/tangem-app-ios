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

    init(cardBatchId: String, cardNumber: String) {
        self.cardBatchId = cardBatchId
        self.cardNumberHash = cardNumber.sha256Hash.hexString
    }
}

class TotalBalanceAnalyticsService {
    let totalBalanceCardSupportInfo: TotalBalanceCardSupportInfo
    private let userDefaults = UserDefaults.standard

    private var cardBalanceInfoWasSaved: Bool {
        userDefaults.data(forKey: totalBalanceCardSupportInfo.cardNumberHash) != nil
    }

    init(totalBalanceCardSupportInfo: TotalBalanceCardSupportInfo) {
        self.totalBalanceCardSupportInfo = totalBalanceCardSupportInfo
    }

    func sendFirstLoadBalanceEventForCard(tokenItemViewModels: [TokenItemViewModel], balance: Decimal) {
        let fullCurrenciesName: String = tokenItemViewModels
            .filter({ $0.fiatValue > 0 })
            .map({ $0.currencySymbol })
            .reduce("") { partialResult, currencySymbol in
                "\(partialResult)\(partialResult.isEmpty ? "" : " / ")\(currencySymbol)"
            }

        var params: [Analytics.ParameterKey: String] = [.state: balance > 0 ? "Full" : "Empty"]
        if !fullCurrenciesName.isEmpty {
            params[.basicCurrency] = fullCurrenciesName
        }
        params[.batchId] = totalBalanceCardSupportInfo.cardBatchId
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
            let fullCurrenciesName: String = tokenItemViewModels
                .filter({ $0.fiatValue > 0 })
                .map({ $0.currencySymbol })
                .reduce("") { partialResult, currencySymbol in
                    "\(partialResult)\(partialResult.isEmpty ? "" : " / ")\(currencySymbol)"
                }
            Analytics.log(.toppedUp, params: [.basicCurrency: fullCurrenciesName])
            let encodeToData = try? JSONEncoder().encode(balance)
            userDefaults.set(encodeToData, forKey: totalBalanceCardSupportInfo.cardNumberHash)
        }
    }
}
