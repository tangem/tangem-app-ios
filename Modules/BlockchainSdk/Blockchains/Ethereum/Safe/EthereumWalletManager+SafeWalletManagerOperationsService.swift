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
        async let gasLimit = getGasLimit(
            to: innerCall.to,
            from: defaultSourceAddress,
            value: innerCall.value.hexString,
            data: innerCall.data.hex().addHexPrefix()
        )
        .mapError { EthereumMapper.mapError($0) }
        .async()
        async let gasPrice = getGasPrice().async()
        async let state = getSafeState()

        return try await SafeOperationFeeCalculator.fee(
            estimate: SafeInnerCallEstimate(gasLimit: gasLimit, gasPrice: gasPrice),
            state: state,
            parameters: parameters
        )
    }
}
