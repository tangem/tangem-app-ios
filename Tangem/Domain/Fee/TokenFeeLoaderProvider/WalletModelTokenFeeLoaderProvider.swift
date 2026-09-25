//
//  WalletModelTokenFeeLoaderProvider.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk

struct WalletModelTokenFeeLoaderProvider {
    let walletModel: any WalletModel
}

// MARK: - TokenFeeLoaderProvider

extension WalletModelTokenFeeLoaderProvider: TokenFeeLoaderProvider {
    func makeMainTokenFeeLoader() -> TokenFeeLoader {
        let tokenItem = walletModel.tokenItem

        if walletModel.isDemo {
            return DemoTokenFeeLoader(tokenItem: tokenItem)
        }

        // A wallet living at a joint account's Safe pays its relayer, not the network
        if walletModel.isJointAccountParticipant, let safeOperationsService = walletModel.safeWalletManagerOperationsService {
            return JointAccountOperationTokenFeeLoader(
                tokenItem: tokenItem,
                feeTokenItem: .blockchain(tokenItem.blockchainNetwork),
                safeOperationsService: safeOperationsService,
                parametersProvider: CommonJointOperationParametersProvider()
            )
        }

        let tokenFeeLoader = CommonTokenFeeLoader(
            tokenItem: tokenItem,
            transactionFeeProvider: walletModel.transactionFeeProvider
        )

        if let compiledTransactionFeeProvider = walletModel.compiledTransactionFeeProvider {
            return CommonSolanaTokenFeeLoader(
                tokenFeeLoader: tokenFeeLoader,
                compiledTransactionFeeProvider: compiledTransactionFeeProvider
            )
        }

        if let ethereumNetworkProvider = walletModel.ethereumNetworkProvider {
            return CommonEthereumTokenFeeLoader(
                feeBlockchain: tokenItem.blockchain,
                tokenFeeLoader: tokenFeeLoader,
                ethereumNetworkProvider: ethereumNetworkProvider
            )
        }

        if tokenItem.blockchain.isPsbtDexSwapSupported {
            return CommonBitcoinTokenFeeLoader(tokenItem: tokenItem, tokenFeeLoader: tokenFeeLoader)
        }

        if let tronTransactionFeeProvider = walletModel.tronTransactionFeeProvider {
            return CommonTronTokenFeeLoader(tokenFeeLoader: tokenFeeLoader, tronTransactionFeeProvider: tronTransactionFeeProvider)
        }

        return tokenFeeLoader
    }

    func makeGaslessTokenFeeLoader(feeToken: BSDKToken, yieldFeeContext: GaslessYieldFeeContext?) -> TokenFeeLoader? {
        let tokenItem = walletModel.tokenItem

        // Until paying in a token is turned on, a Safe refunds its relayer in the coin and no token option is offered.
        // When it is, the Safe pays out of the tokens it holds itself, so the yield-backed context has no say here.
        if walletModel.isJointAccountParticipant, let safeOperationsService = walletModel.safeWalletManagerOperationsService {
            if !FeatureProvider.isAvailable(.jointAccountsGaslessTokenFee) {
                return nil
            }

            return JointAccountOperationTokenFeeLoader(
                tokenItem: tokenItem,
                feeTokenItem: .token(feeToken, tokenItem.blockchainNetwork),
                safeOperationsService: safeOperationsService,
                parametersProvider: CommonJointOperationParametersProvider()
            )
        }

        if case .tron = tokenItem.blockchain, walletModel.tronGaslessTransactionsBuilder != nil {
            return CommonTronGaslessTokenFeeLoader(
                tokenItem: tokenItem,
                feeToken: feeToken,
                sourceAddress: walletModel.defaultAddressString,
                userWalletId: walletModel.userWalletId
            )
        }

        guard let gaslessTransactionFeeProvider = walletModel.ethereumGaslessTransactionFeeProvider else {
            assertionFailure("WalletModel does not have ethereumGaslessTransactionFeeProvider")
            return nil
        }

        return CommonGaslessTokenFeeLoader(
            tokenItem: tokenItem,
            feeToken: feeToken,
            gaslessTransactionFeeProvider: gaslessTransactionFeeProvider,
            yieldFeeContext: yieldFeeContext
        )
    }

    func makeCustomFeeProvider() -> (any CustomFeeProvider)? {
        let tokenItem = walletModel.tokenItem
        let feeTokenItem = walletModel.feeTokenItem

        // A Safe operation is refunded on the relayer's terms, so there is nothing here for the sender to hand-edit
        guard !walletModel.isJointAccountParticipant else {
            return nil
        }

        switch tokenItem.blockchain {
        case .bitcoin:
            guard let bitcoinTransactionFeeCalculator = walletModel.bitcoinTransactionFeeCalculator else {
                return nil
            }

            return BitcoinCustomFeeService(
                tokenItem: tokenItem,
                feeTokenItem: feeTokenItem,
                bitcoinTransactionFeeCalculator: bitcoinTransactionFeeCalculator
            )

        case .kaspa:
            return KaspaCustomFeeService(tokenItem: tokenItem, feeTokenItem: feeTokenItem)

        case _ where tokenItem.blockchain.isEvm:
            return EVMCustomFeeService(sourceTokenItem: tokenItem, feeTokenItem: feeTokenItem)

        default:
            return nil
        }
    }
}
