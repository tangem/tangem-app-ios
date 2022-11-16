//
//  ExchangingFacade.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation

public protocol OneInchApiServiceProtocol: AnyObject {
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

class OneInchApiService: OneInchApiServiceProtocol {
    let isDebug: Bool
    private lazy var networkService: NetworkService = NetworkService(isDebug: isDebug)

    init(isDebug: Bool = false) {
        self.isDebug = isDebug
    }

    func healthCheck(blockchain: ExchangeBlockchain) async -> Result<HealthCheck, ExchangeInchError> {
        await networkService.request(with: BaseTarget(target: HealthCheckTarget.healthCheck(blockchain: blockchain)))
    }

    func tokens(blockchain: ExchangeBlockchain) async -> Result<TokensList, ExchangeInchError> {
        await networkService.request(with: BaseTarget(target: InfoTarget.tokens(blockchain: blockchain)))
    }

    func presets(blockchain: ExchangeBlockchain) async -> Result<PresetsConfiguration, ExchangeInchError> {
        await networkService.request(with: BaseTarget(target: InfoTarget.presets(blockchain: blockchain)))
    }

    func liquiditySources(blockchain: ExchangeBlockchain) async -> Result<LiquiditySourcesList, ExchangeInchError> {
        await networkService.request(with: BaseTarget(target: InfoTarget.liquiditySources(blockchain: blockchain)))
    }

    func quote(blockchain: ExchangeBlockchain, parameters: QuoteParameters) async -> Result<QuoteData, ExchangeInchError> {
        await networkService.request(with: BaseTarget(target: SwapTarget.quote(blockchain: blockchain, parameters: parameters)))
    }

    func swap(blockchain: ExchangeBlockchain, parameters: SwapParameters) async -> Result<SwapData, ExchangeInchError> {
        await networkService.request(with: BaseTarget(target: SwapTarget.swap(blockchain: blockchain, parameters: parameters)))
    }

    func spender(blockchain: ExchangeBlockchain) async -> Result<ApproveSpender, ExchangeInchError> {
        await networkService.request(with: BaseTarget(target: ApproveTarget.spender(blockchain: blockchain)))
    }

    func approveTransaction(blockchain: ExchangeBlockchain, approveTransactionParameters: ApproveTransactionParameters) async -> Result<ApprovedTransactionData, ExchangeInchError> {
        await networkService.request(with: BaseTarget(target: ApproveTarget.transaction(blockchain: blockchain, params: approveTransactionParameters)))
    }

    func allowance(blockchain: ExchangeBlockchain, allowanceParameters: ApproveAllowanceParameters) async -> Result<ApprovedAllowance, ExchangeInchError> {
        await networkService.request(with: BaseTarget(target: ApproveTarget.allowance(blockchain: blockchain, params: allowanceParameters)))
    }
}
