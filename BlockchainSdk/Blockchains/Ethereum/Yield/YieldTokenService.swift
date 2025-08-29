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
    func getYieldModule(for address: String) async throws -> String?
    func getYieldTokenData(for yieldToken: String) async throws -> YieldTokenData
    func getYieldBalances(for yieldToken: String) async throws -> YieldBalances
}

extension EthereumNetworkService: YieldTokenService {
    public func getYieldModule(for address: String) async throws -> String? {
        let method = YieldModuleMethod(address: address)

        let request = YieldSmartContractRequest(
            contractAddress: Constants.yieldModuleFactoryContractAddress,
            method: method
        )

        let result = try await ethCall(request: request).async()
        
        if result.removeHexPrefix().isEmpty {
            return nil
        }
        
        return result
    }

    public func getYieldTokenData(for yieldToken: String) async throws -> YieldTokenData {
        let method = YieldTokenDataMethod(yieldTokenAddress: yieldToken)

        let request = YieldSmartContractRequest(
            contractAddress: Constants.yieldModuleFactoryContractAddress,
            method: method
        )
        
        let tokenData = try await ethCall(request: request).async()

        return try YieldServiceYieldTokenDataConverter.convert(tokenData)
    }
    
    public func getYieldBalances(for yieldToken: String) async throws -> YieldBalances {
        let effectiveMethod = EffectiveBalanceMethod(yieldTokenAddress: yieldToken)

        let effectiveRequest = YieldSmartContractRequest(
            contractAddress: Constants.yieldModuleFactoryContractAddress,
            method: effectiveMethod
        )
        
        let protocolMethod = ProtocolBalanceMethod(yieldTokenAddress: yieldToken)

        let protocolRequest = YieldSmartContractRequest(
            contractAddress: Constants.yieldModuleFactoryContractAddress,
            method: effectiveMethod
        )
        
        async let effectiveBalanceRequest = ethCall(request: effectiveRequest).async()
        async let protocolBalanceRequest = ethCall(request: protocolRequest).async()
        
        let (effectiveBalanceData, protocolBalanceData) = try await (effectiveBalanceRequest, protocolBalanceRequest)
        
        let effectiveBalance = BigUInt(Data(hexString: effectiveBalanceData))
        let protocolBalance = BigUInt(Data(hexString: effectiveBalanceData))

        return YieldBalances(
            effective: effectiveBalance,
            protocol: protocolBalance
        )
    }
}

private extension EthereumNetworkService {
    enum Constants {
        static let yieldModuleFactoryContractAddress = "0xE21829B57f1D8d5461d3F38340A6e491c62A6990"
    }
}
