//
//  EthereumOptimisticRollupWalletManager.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine

/// Used by Optimism, Base, and other Ethereum L2s with optimistic rollups.
final class EthereumOptimisticRollupWalletManager: EthereumWalletManager {
    let l1SmartContractAddress: String
    let l1FeeMultiplier: Decimal

    init(
        wallet: Wallet,
        addressConverter: EthereumAddressConverter,
        txBuilder: EthereumTransactionBuilder,
        networkService: EthereumNetworkService,
        yieldSupplyService: YieldSupplyService? = nil,
        pendingTransactionsManager: EthereumPendingTransactionsManager,
        l1SmartContractAddress: String,
        l1FeeMultiplier: Decimal
    ) {
        self.l1SmartContractAddress = l1SmartContractAddress
        self.l1FeeMultiplier = l1FeeMultiplier

        super.init(
            wallet: wallet,
            addressConverter: addressConverter,
            txBuilder: txBuilder,
            networkService: networkService,
            yieldSupplyService: yieldSupplyService,
            pendingTransactionsManager: pendingTransactionsManager
        )
    }

    /// We are override this method to combine the three fee's components in the `Optimistic-Ethereum` network.
    /// Read more:
    /// https://community.optimism.io/docs/developers/build/transaction-fees/#the-l1-data-fee
    /// https://help.optimism.io/hc/en-us/articles/4411895794715-How-do-transaction-fees-on-Optimism-work
    /// https://docs.optimism.io/op-stack/transactions/fees#operator-fee
    /// Short information:
    /// `L2` - Used to provide this transaction in the `Optimistic-etherium` network like a usual tx.
    /// `L1` - Used to processing a transaction in the `Etherium` network  for "safety".
    /// `Operator` - Charged by the chain operator for the `L2` gas limit. Zero if the chain doesn't support it.
    /// `L1` and `Operator` fees are calculated by the smart-contract oracle and added by the network automatically after the tx is sent.
    /// The node checks the balance against all three, so they're added to the fee for showing to a user and to keep the max amount sendable.
    /// When we're building transaction we have to used `gasLimit`, `gasPrice` or `baseFee` ONLY from `L2`
    override func getFee(
        destination: String,
        value: String?,
        data: Data?,
        stateOverride: EthereumStateOverride? = nil
    ) -> AnyPublisher<[Fee], Error> {
        do {
            let destination = try addressConverter.convertToETHAddress(destination)

            return super.getFee(destination: destination, value: value, data: data, stateOverride: stateOverride)
                .withWeakCaptureOf(self)
                .flatMap { walletManager, layer2Fees -> AnyPublisher<([Fee], Decimal), Error> in
                    // We use EthereumFeeParameters without increase
                    guard let fee = layer2Fees.first else {
                        return .anyFail(error: BlockchainSdkError.failedToLoadFee)
                    }

                    return Publishers.Zip(
                        walletManager.getLayer1Fee(destination: destination, value: value, data: data, fee: fee),
                        walletManager.getOperatorFee(fee: fee)
                    )
                    .map { layer1Fee, operatorFee in (layer2Fees, layer1Fee + operatorFee) }
                    .eraseToAnyPublisher()
                }
                .map { layer2Fees, additionalFee -> [Fee] in
                    layer2Fees.map { fee in
                        let newAmount = Amount(with: fee.amount, value: fee.amount.value + additionalFee)
                        let newFee = Fee(newAmount, parameters: fee.parameters)
                        return newFee
                    }
                }
                .eraseToAnyPublisher()
        } catch {
            return .anyFail(error: error)
        }
    }
}

// MARK: - Private

private extension EthereumOptimisticRollupWalletManager {
    func getLayer1Fee(
        destination: String,
        value: String?,
        data: Data?,
        fee: Fee
    ) -> AnyPublisher<Decimal, Error> {
        do {
            let hexTransactionData = try txBuilder.buildDummyTransactionForL1(destination: destination, value: value, data: data, fee: fee)
            return networkService
                .read(contractAddress: l1SmartContractAddress, method: EthereumOptimisticRollupSmartContractMethod.getL1Fee(data: hexTransactionData))
                .withWeakCaptureOf(self)
                .tryMap { walletManager, response in
                    guard var value = EthereumUtils.parseEthereumDecimal(response, decimalsCount: walletManager.wallet.blockchain.decimalCount) else {
                        throw BlockchainSdkError.failedToLoadFee
                    }

                    value = value * walletManager.l1FeeMultiplier
                    return value
                }
                // We can ignore errors so as not to block users
                // This L1Fee value is only needed to inform users. It will not used in the transaction
                // Unfortunately L1 fee doesn't work well
                .replaceError(with: 0)
                .setFailureType(to: Error.self)
                .eraseToAnyPublisher()
        } catch {
            return .anyFail(error: error)
        }
    }

    func getOperatorFee(fee: Fee) -> AnyPublisher<Decimal, Error> {
        guard let gasLimit = (fee.parameters as? EthereumFeeParameters)?.gasLimit else {
            return .justWithError(output: 0)
        }

        return networkService
            .read(contractAddress: l1SmartContractAddress, method: EthereumOptimisticRollupSmartContractMethod.getOperatorFee(gasUsed: gasLimit))
            .withWeakCaptureOf(self)
            .tryMap { walletManager, response in
                guard let value = EthereumUtils.parseEthereumDecimal(response, decimalsCount: walletManager.wallet.blockchain.decimalCount) else {
                    throw BlockchainSdkError.failedToLoadFee
                }

                return value
            }
            .replaceError(with: 0)
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
    }
}
