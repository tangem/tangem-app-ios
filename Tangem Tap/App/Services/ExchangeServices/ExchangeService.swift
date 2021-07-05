//
//  ExchangeService.swift
//  Tangem Tap
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation

protocol ExchangeService: AnyObject {
    var buyCloseUrl: String { get }
    var sellCloseUrl: String { get }
    func canBuy(_ currency: String) -> Bool
    func canSell(_ currency: String) -> Bool
    func getBuyUrl(currencySymbol: String, walletAddress: String) -> URL?
    func getSellUrl(currencySymbol: String, walletAddress: String) -> URL?
}
