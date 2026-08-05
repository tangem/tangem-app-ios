//
//  TokenSummaryInput.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine

/// `swapCandidates` is a snapshot taken on tap — the sheet is dismissed before any navigation runs.
struct TokenSummaryInput {
    let token: MarketsTokenModel
    let indicators: [TokenSummaryIndicator]
    let primaryActionPublisher: AnyPublisher<TokenSummaryPrimaryAction?, Never>
    let holdings: [any WalletModel]
    let swapCandidates: [any WalletModel]
    let underivedTokens: [MarketsPortfolioTokenListViewModel.UnderivedToken]
    let addTokenInputData: MarketsAddTokenFlowConfigurationFactory.InputData
    let isTokenAddedEverywhere: Bool
    let iconURL: URL
}
