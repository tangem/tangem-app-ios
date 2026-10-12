//
//  JointAccountOperationTokenFeeLoader.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk

/// Prices a transfer from a joint account as the Safe will refund it: one option, in the coin or in a token the Safe
/// holds, with the gas terms carried inside the fee so that what is signed later is exactly what was shown.
struct JointAccountOperationTokenFeeLoader {
    private let tokenItem: TokenItem
    private let feeTokenItem: TokenItem
    private let safeOperationsService: SafeWalletManagerOperationsService
    private let parametersProvider: JointOperationParametersProvider

    private let balanceConverter = BalanceConverter()

    init(
        tokenItem: TokenItem,
        feeTokenItem: TokenItem,
        safeOperationsService: SafeWalletManagerOperationsService,
        parametersProvider: JointOperationParametersProvider
    ) {
        self.tokenItem = tokenItem
        self.feeTokenItem = feeTokenItem
        self.safeOperationsService = safeOperationsService
        self.parametersProvider = parametersProvider
    }
}

// MARK: - TokenFeeLoader

extension JointAccountOperationTokenFeeLoader: TokenFeeLoader {
    /// Only a CEX swap asks for a fee without a destination, and a joint account does not swap.
    func estimatedFee(amount: Decimal) async throws -> [BSDKFee] {
        throw TokenFeeLoaderError.tokenFeeLoaderNotFound
    }

    func getFee(amount: Decimal, destination: String) async throws -> [BSDKFee] {
        let sendingAmount = BSDKAmount(with: tokenItem.blockchain, type: tokenItem.amountType, value: amount)
        let innerCall = try safeOperationsService.makeSafeInnerTransferCall(amount: sendingAmount, destination: destination)
        let gasToken = try await makeGasToken()
        let parameters = try await parametersProvider.makeParameters(gasToken: gasToken)
        let fee = try await safeOperationsService.getSafeOperationFee(innerCall: innerCall, parameters: parameters)

        return [fee]
    }
}

// MARK: - Private

private extension JointAccountOperationTokenFeeLoader {
    func makeGasToken() async throws -> SafeGasToken {
        switch feeTokenItem {
        case .blockchain(let blockchainNetwork):
            return .coin(blockchainNetwork.blockchain)

        case .token(let token, let blockchainNetwork):
            guard let tokenId = token.id else {
                throw TokenFeeLoaderError.feeTokenIdNotFound
            }

            let nativeToTokenRate = try await balanceConverter.cryptoToCryptoRate(from: blockchainNetwork.blockchain.coinId, to: tokenId)
            return .token(token, blockchain: blockchainNetwork.blockchain, nativeToTokenRate: nativeToTokenRate)
        }
    }
}
