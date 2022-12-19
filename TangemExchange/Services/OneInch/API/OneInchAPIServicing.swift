//
//  OneInchAPIServicing.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation

public protocol OneInchAPIServicing {

    // Check status of service
    func healthCheck(blockchain: ExchangeBlockchain) async -> Result<HealthCheck, ExchangeProviderError>
    func tokens(blockchain: ExchangeBlockchain) async -> Result<TokensList, ExchangeProviderError>

    func presets(blockchain: ExchangeBlockchain) async -> Result<PresetsConfiguration, ExchangeProviderError>
    func liquiditySources(blockchain: ExchangeBlockchain) async -> Result<LiquiditySourcesList, ExchangeProviderError>

    // Find best quote to exchange
    func quote(blockchain: ExchangeBlockchain,
               parameters: QuoteParameters) async -> Result<QuoteData, ExchangeProviderError>

    // Generating data for exchange
    func swap(blockchain: ExchangeBlockchain,
              parameters: ExchangeParameters) async -> Result<ExchangeData, ExchangeProviderError>

    // Address of the 1inch router that must be trusted to spend funds for the exchange
    func spender(blockchain: ExchangeBlockchain) async -> Result<ApproveSpender, ExchangeProviderError>

    // Generate data for calling the contract in order to allow the 1inch router to spend funds
    func approveTransaction(blockchain: ExchangeBlockchain,
                            approveTransactionParameters: ApproveTransactionParameters) async -> Result<ApprovedTransactionData, ExchangeProviderError>

    // Get the number of tokens that the 1inch router is allowed to spend
    func allowance(blockchain: ExchangeBlockchain,
                   allowanceParameters: ApproveAllowanceParameters) async -> Result<ApprovedAllowance, ExchangeProviderError>
}

