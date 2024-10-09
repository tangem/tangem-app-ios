//
//  TokenMarketsDetailsRoutable.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

protocol TokenMarketsDetailsRoutable: AnyObject, MarketsPortfolioContainerRoutable {
    func openURL(_ url: URL)
    func openTokenSelector(with model: TokenMarketsDetailsModel, walletDataProvider: MarketsWalletDataProvider)
    func openMail(with dataCollector: EmailDataCollector, emailType: EmailType)
    func closeModule()
    func openExchangesList(tokenId: String, numberOfExchangesListedOn: Int, presentationStyle: MarketsTokenDetailsPresentationStyle)
}
