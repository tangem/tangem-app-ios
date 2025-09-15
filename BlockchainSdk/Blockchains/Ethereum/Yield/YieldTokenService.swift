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
    func getYieldModuleState(for address: String, contractAddress: String) async throws -> YieldModuleSmartContractState
    func getYieldBalance(for yieldModule: String, contractAddress: String) async throws -> Decimal
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

    public func getYieldModuleState(for address: String, contractAddress: String) async throws -> YieldModuleSmartContractState {
        let yieldModule = try await getYieldModule(for: address)

        if let yieldModule {
            let yieldTokenData = try await getYieldTokenData(for: yieldModule, contractAddress: contractAddress)

            let maxNetworkFee = yieldTokenData.maxNetworkFee

            let initializationState: YieldModuleSmartContractState.InitializationState
            if yieldTokenData.initialized {
                if yieldTokenData.active {
                    let balance = try? await getYieldBalance(for: yieldModule, contractAddress: contractAddress)
                    initializationState = .initialized(
                        activeState: .active(
                            info: YieldModuleSmartContractState.ActiveStateInfo(
                                balance: balance,
                                maxNetworkFee: maxNetworkFee
                            )
                        )
                    )
                } else {
                    initializationState = .initialized(activeState: .notActive)
                }
            } else {
                initializationState = .notInitialized
            }
            return .deployed(.init(yieldModule: yieldModule, initializationState: initializationState))
        } else {
            return .notDeployed
        }
    }

    public func getYieldBalance(for yieldModule: String, contractAddress: String) async throws -> Decimal {
        let effectiveMethod = EffectiveBalanceMethod(yieldTokenAddress: contractAddress)

        let effectiveRequest = YieldSmartContractRequest(
            contractAddress: yieldModule,
            method: effectiveMethod
        )

        let effectiveBalance = try await ethCall(request: effectiveRequest).async()

        guard let result = EthereumUtils.parseEthereumDecimal(effectiveBalance, decimalsCount: decimals) else {
            throw YieldServiceError.unableToParseData
        }

        return result
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
