//
//  JointOperationFeeBoundsProvider.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import BigInt
import BlockchainSdk
import TangemFoundation

struct JointOperationFeeBoundsProvider {
    @Injected(\.gaslessTransactionsNetworkManager) private var gaslessTransactionsNetworkManager: GaslessTransactionsNetworkManager

    private let balanceConverter = BalanceConverter()

    func displayBounds(chainId: Int) -> JointOperationVerifier.FeeBounds {
        JointOperationVerifier.FeeBounds(
            refundReceiver: JointOperationFeeConstants.refundReceiver,
            allowedGasTokenAddresses: allowedGasTokenAddresses(chainId: chainId),
            gasPriceCeiling: nil
        )
    }

    func signingBounds(
        operation: JointAccountOperation,
        blockchain: BSDKBlockchain,
        walletModels: [any WalletModel],
        networkGasPrice: BigUInt
    ) async throws -> JointOperationVerifier.FeeBounds {
        let gasToken = try await resolveGasToken(
            address: operation.safeTransaction.gasToken,
            chainId: operation.chainId,
            blockchain: blockchain,
            walletModels: walletModels
        )

        let coinCeiling = networkGasPrice * JointOperationFeeConstants.gasPriceCeilingMultiplier

        return JointOperationVerifier.FeeBounds(
            refundReceiver: JointOperationFeeConstants.refundReceiver,
            allowedGasTokenAddresses: allowedGasTokenAddresses(chainId: operation.chainId),
            gasPriceCeiling: gasToken.gasPrice(fromCoinGasPrice: coinCeiling)
        )
    }

    private func allowedGasTokenAddresses(chainId: Int) -> Set<String> {
        if gaslessTransactionsNetworkManager.availableFeeTokens.isEmpty {
            gaslessTransactionsNetworkManager.updateAvailableTokens()
        }

        let feeTokenAddresses = gaslessTransactionsNetworkManager.availableFeeTokens
            .filter { $0.chainId == chainId }
            .map { $0.tokenAddress.lowercased() }

        return Set(feeTokenAddresses).union([SafeGasToken.coinGasTokenRawValue.lowercased()])
    }

    private func resolveGasToken(
        address: String,
        chainId: Int,
        blockchain: BSDKBlockchain,
        walletModels: [any WalletModel]
    ) async throws -> SafeGasToken {
        if address.caseInsensitiveEquals(to: SafeGasToken.coinGasTokenRawValue) {
            return .coin(blockchain)
        }

        let feeWalletModel = walletModels.first {
            $0.tokenItem.blockchain.chainId == chainId && $0.tokenItem.contractAddress?.caseInsensitiveEquals(to: address) == true
        }

        guard case .token(let token, let blockchainNetwork) = feeWalletModel?.tokenItem, let tokenId = token.id else {
            throw JointOperationError.operationVerificationFailed(.refundMismatch)
        }

        let nativeToTokenRate = try await balanceConverter.cryptoToCryptoRate(from: blockchainNetwork.blockchain.coinId, to: tokenId)
        return .token(token, blockchain: blockchainNetwork.blockchain, nativeToTokenRate: nativeToTokenRate)
    }
}
