//
//  EthereumWalletManager+SafeWalletManagerOperationsService.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import BigInt
import TangemFoundation

// MARK: - SafeWalletManagerOperationsService

/// The wallet's own address is the Safe: every read here is made for it.
extension EthereumWalletManager: SafeWalletManagerOperationsService {
    func getSafeState() async throws -> SafeContractState {
        guard let nonce = try await getSafeNonce(for: wallet.address).async() else {
            return .notDeployed
        }

        async let owners = getSafeOwners(for: wallet.address).async()
        async let threshold = getSafeThreshold(for: wallet.address).async()

        return try await .deployed(nonce: nonce, owners: owners, threshold: threshold)
    }

    func makeSafeInnerTransferCall(amount: Amount, destination: String) throws -> SafeInnerCall {
        switch amount.type {
        case .coin:
            guard let encodedValue = amount.encoded else {
                throw SafeOperationError.unsupportedInnerCall
            }

            let address = try addressConverter.convertToETHAddress(destination)

            return SafeInnerCall(to: address, value: BigUInt(encodedValue), data: Data())
        case .token(let token):
            let data = try buildForTokenTransfer(destination: destination, amount: amount)

            return SafeInnerCall(to: token.contractAddress, value: 0, data: data)
        case .reserve, .feeResource:
            throw SafeOperationError.unsupportedInnerCall
        }
    }

    func getSafeOperationFee(innerCall: SafeInnerCall, parameters: SafeOperationParameters) async throws -> Fee {
        // The wallet's `from` is the Safe already, so one fee request both estimates the inner call and prices it
        async let fees = getFee(destination: innerCall.to, value: innerCall.value.hexString, data: innerCall.data).async()
        async let state = getSafeState()

        let marketFee = try await SafeOperationFeeCalculator.marketFeeParameters(from: fees)
        let estimate = SafeInnerCallEstimate(
            gasLimit: marketFee.gasLimit,
            gasPrice: SafeOperationFeeCalculator.gasPrice(of: marketFee)
        )

        return try await SafeOperationFeeCalculator.fee(
            estimate: estimate,
            state: state,
            parameters: parameters
        )
    }
}
