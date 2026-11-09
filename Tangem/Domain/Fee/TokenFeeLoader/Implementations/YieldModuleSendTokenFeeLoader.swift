//
//  YieldModuleSendTokenFeeLoader.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk
import TangemFoundation

struct YieldModuleSendTokenFeeLoader {
    let tokenItem: TokenItem
    let tokenFeeLoader: any TokenFeeLoader
    let yieldModuleManager: any YieldModuleManager
    let ethereumNetworkProvider: any EthereumNetworkProvider
}

// MARK: - TokenFeeLoading

extension YieldModuleSendTokenFeeLoader: TokenFeeLoading {
    func estimatedFee(amount: Decimal) async throws -> [BSDKFee] {
        try await tokenFeeLoader.estimatedFee(amount: amount)
    }

    func getFee(amount: Decimal, destination: String) async throws -> [BSDKFee] {
        guard let amountValue = BSDKAmount(with: tokenItem.blockchain, type: tokenItem.amountType, value: amount).bigUIntValue,
              let upgradingSendCallData = try await yieldModuleManager.upgradingSendCallData(
                  destination: destination,
                  amount: amountValue
              ) else {
            return try await tokenFeeLoader.getFee(amount: amount, destination: destination)
        }

        let fees = try await ethereumNetworkProvider
            .getFee(destination: upgradingSendCallData.yieldContractAddress, value: nil, data: upgradingSendCallData.data)
            .async()

        return fees.map {
            $0.increasingGasLimit(
                byPercents: EthereumFeeParametersConstants.yieldModuleGasLimitIncreasePercent,
                blockchain: tokenItem.blockchain,
                decimalValue: tokenItem.blockchain.decimalValue
            )
        }
    }
}
