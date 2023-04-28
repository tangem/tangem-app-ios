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
    func healthCheck(blockchain: SwappingBlockchain) async -> Result<HealthCheck, SwappingProviderError>
    func tokens(blockchain: SwappingBlockchain) async -> Result<TokensList, SwappingProviderError>

    func presets(blockchain: SwappingBlockchain) async -> Result<PresetsConfiguration, SwappingProviderError>
    func liquiditySources(blockchain: SwappingBlockchain) async -> Result<LiquiditySourcesList, SwappingProviderError>

    // Find best quote to swapping
    func quote(
        blockchain: SwappingBlockchain,
        parameters: QuoteParameters
    ) async -> Result<QuoteData, SwappingProviderError>

    // Generating data for swapping
    func swap(
        blockchain: SwappingBlockchain,
        parameters: SwappingParameters
    ) async -> Result<SwappingData, SwappingProviderError>

    // Address of the 1inch router that must be trusted to spend funds for the swapping
    func spender(blockchain: SwappingBlockchain) async -> Result<ApproveSpender, SwappingProviderError>

    // Generate data for calling the contract in order to allow the 1inch router to spend funds
    func approveTransaction(
        blockchain: SwappingBlockchain,
        approveTransactionParameters: ApproveTransactionParameters
    ) async -> Result<ApprovedTransactionData, SwappingProviderError>

    // Get the number of tokens that the 1inch router is allowed to spend
    func allowance(
        blockchain: SwappingBlockchain,
        allowanceParameters: ApproveAllowanceParameters
    ) async -> Result<ApprovedAllowance, SwappingProviderError>
}
