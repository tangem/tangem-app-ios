//
//  MarketsTokenDetailsRoutable.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

protocol MarketsTokenDetailsRoutable: AnyObject, MarketsPortfolioContainerRoutable {
    func openURL(_ url: URL)
    @MainActor
    func openAccountsSelector(with model: MarketsTokenDetailsModel, walletDataProvider: MarketsWalletDataProvider)
    func openMail(with dataCollector: EmailDataCollector, emailType: EmailType)
    func closeModule()
    func openExchangesList(tokenId: String, numberOfExchangesListedOn: Int)
    @MainActor
    func openNews(newsIds: [Int], selectedIndex: Int)
    func shareTokenDetails(url: URL)
    @MainActor
    func openInfoDialogue(title: String, message: String)
    @MainActor
    func openFullDescriptionDialogue(title: String, description: String, onGenerateAITapAction: @escaping () -> Void)
    @MainActor
    func openSecurityScoreDetails(
        with providers: [MarketsTokenDetailsSecurityScore.Provider],
        routable: MarketsTokenDetailsSecurityScoreDetailsRoutable
    )
}
