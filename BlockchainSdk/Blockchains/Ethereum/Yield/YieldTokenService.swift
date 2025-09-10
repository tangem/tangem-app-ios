//
//  YieldTokenService.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import BigInt

public protocol YieldTokenService {
    func getAPY(for contractAddress: String) async throws -> Decimal
    func calculateYieldAddress(for address: String) async throws -> String
    func getYieldModuleState(for address: String, contractAddress: String) async throws -> YieldModuleState
    func getYieldBalances(
        for yieldToken: String,
        tokens: [Token]
    ) async throws -> [Token: Result<YieldBalances?, Error>]
}

extension EthereumNetworkService: YieldTokenService {
    public func getAPY(for contractAddress: String) async throws -> Decimal {
        let supplyAPYMethod = ReservedDataMethod(contractAddress: contractAddress)

        let supplyAPYRequest = YieldSmartContractRequest(
            contractAddress: YieldConstants.aavePoolContractAddress,
            method: supplyAPYMethod
        )

        async let supplyAPYResult = ethCall(request: supplyAPYRequest).async()

        let serviceFeeRateMethod = ServiceFeeRateMethod()

        let serviceFeeRateRequest = YieldSmartContractRequest(
            contractAddress: YieldConstants.yieldProcessorContractAddress,
            method: serviceFeeRateMethod
        )

        async let serviceFeeRateResult = ethCall(
            request: serviceFeeRateRequest
        ).async()

        let (supplyAPYData, serviceFeeRateData) = try await (supplyAPYResult, serviceFeeRateResult)

        let supplyAPYPercent = try YieldResponseMapper.mapAPY(supplyAPYData)
        let serviceFeeRate = try YieldResponseMapper.mapFeeRate(serviceFeeRateData)

        return supplyAPYPercent * (1 - serviceFeeRate)
    }

    func calculateYieldAddress(for address: String) async throws -> String {
        let method = CalculateYieldModuleAddressMethod(sourceAddress: address)

        let request = YieldSmartContractRequest(
            contractAddress: YieldConstants.yieldModuleFactoryContractAddress,
            method: method
        )

        let result = try await ethCall(request: request).async()

        let resultNoHex = result.removeHexPrefix()

        return resultNoHex.stripLeadingZeroes().addHexPrefix()
    }

    public func getYieldModuleState(for address: String, contractAddress: String) async throws -> YieldModuleState {
        let yieldModule = try await getYieldModule(for: address)

        if let yieldModule {
            let yieldTokenData = try await getYieldTokenData(for: yieldModule, contractAddress: contractAddress)

            let maxNetworkFee = yieldTokenData.maxNetworkFee

            let initializationState: YieldModuleState.InitializationState = if yieldTokenData.initialized {
                if yieldTokenData.active {
                    .initialized(activeState: .active(maxNetworkFee: maxNetworkFee))
                } else {
                    .initialized(activeState: .notActive)
                }
            } else {
                .notInitialized
            }
            return .deployed(.init(yieldModule: yieldModule, initializationState: initializationState))
        } else {
            return .notDeployed
        }
    }

    func getYieldBalances(
        for yieldToken: String,
        tokens: [Token]
    ) async throws -> [Token: Result<YieldBalances?, Error>] {
        try await withThrowingTaskGroup(of: (Token, Result<YieldBalances?, Error>).self) { [weak self] group in
            var result = [Token: Result<YieldBalances?, Error>]()
            tokens.forEach { token in
                group.addTask {
                    do {
                        try Task.checkCancellation()
                        guard let self else {
                            throw CancellationError()
                        }
                        let result = try await self.getYieldBalances(
                            for: yieldToken,
                            contractAddress: token.contractAddress
                        )
                        return (token, .success(result))
                    } catch {
                        return (token, .failure(error))
                    }
                }
            }

            for try await res in group {
                result[res.0] = res.1
            }

            return result
        }
    }

    private func getYieldBalances(for yieldToken: String, contractAddress: String) async throws -> YieldBalances {
        let effectiveMethod = EffectiveBalanceMethod(yieldTokenAddress: contractAddress)

        let effectiveRequest = YieldSmartContractRequest(
            contractAddress: yieldToken,
            method: effectiveMethod
        )

        let protocolMethod = ProtocolBalanceMethod(yieldTokenAddress: contractAddress)

        let protocolRequest = YieldSmartContractRequest(
            contractAddress: yieldToken,
            method: protocolMethod
        )

        async let effectiveBalance = ethCall(request: effectiveRequest).async()
        async let protocolBalance = ethCall(request: protocolRequest).async()

        return try await YieldResponseMapper.mapBalances(
            protocolBalance: protocolBalance,
            effectiveBalance: effectiveBalance
        )
    }

    private func getYieldModule(for address: String) async throws -> String? {
        let method = YieldModuleMethod(address: address)

        let request = YieldSmartContractRequest(
            contractAddress: YieldConstants.yieldModuleFactoryContractAddress,
            method: method
        )

        let result = try await ethCall(request: request).async()

        let resultNoHex = result.removeHexPrefix()
        if resultNoHex.isEmpty || BigUInt(resultNoHex) == 0 {
            return nil
        }

        return resultNoHex.stripLeadingZeroes().addHexPrefix()
    }

    private func getYieldTokenData(for yieldToken: String, contractAddress: String) async throws -> YieldTokenData {
        let method = YieldTokenDataMethod(contractAddress: contractAddress)

        let request = YieldSmartContractRequest(
            contractAddress: yieldToken,
            method: method
        )

        let tokenData = try await ethCall(request: request).async()

        return try YieldResponseMapper.mapTokenData(tokenData)
    }
}
