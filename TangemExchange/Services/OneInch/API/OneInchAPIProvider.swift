//
//  ExchangingFacade.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation

public protocol OneInchAPIProvider {

    // Check status of service
    func healthCheck(blockchain: ExchangeBlockchain) async -> Result<HealthCheck, ExchangeInchError>
    func tokens(blockchain: ExchangeBlockchain) async -> Result<TokensList, ExchangeInchError>

    func presets(blockchain: ExchangeBlockchain) async -> Result<PresetsConfiguration, ExchangeInchError>
    func liquiditySources(blockchain: ExchangeBlockchain) async -> Result<LiquiditySourcesList, ExchangeInchError>

    // Find best quote to exchange
    func quote(blockchain: ExchangeBlockchain,
               parameters: QuoteParameters) async -> Result<QuoteData, ExchangeInchError>

    // Generating data for exchange
    func swap(blockchain: ExchangeBlockchain,
              parameters: SwapParameters) async -> Result<SwapData, ExchangeInchError>

    // Address of the 1inch router that must be trusted to spend funds for the exchange
    func spender(blockchain: ExchangeBlockchain) async -> Result<ApproveSpender, ExchangeInchError>

    // Generate data for calling the contract in order to allow the 1inch router to spend funds
    func approveTransaction(blockchain: ExchangeBlockchain,
                            approveTransactionParameters: ApproveTransactionParameters) async -> Result<ApprovedTransactionData, ExchangeInchError>

    // Get the number of tokens that the 1inch router is allowed to spend
    func allowance(blockchain: ExchangeBlockchain,
                   allowanceParameters: ApproveAllowanceParameters) async -> Result<ApprovedAllowance, ExchangeInchError>
}

