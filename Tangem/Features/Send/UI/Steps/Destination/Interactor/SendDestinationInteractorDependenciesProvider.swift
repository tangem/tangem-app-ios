//
//  SendDestinationInteractorDependenciesProvider.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import BlockchainSdk
import TangemAccounts

class SendDestinationInteractorDependenciesProvider {
    @Injected(\.userWalletRepository) private var userWalletRepository: UserWalletRepository
    lazy var validator: SendDestinationValidator = makeValidator()
    lazy var addressResolver: AddressResolver? = makeAddressResolver()
    lazy var transactionHistoryProvider: SendDestinationTransactionHistoryProvider = makeSendDestinationTransactionHistoryProvider()
    lazy var parametersBuilder: TransactionParamsBuilder = makeTransactionParamsBuilder()
    lazy var analyticsLogger: SendDestinationAnalyticsLogger = makeAnalyticsLogger()

    var suggestedWallets: [SendDestinationSuggestedWallet] {
        switch receivedTokenType {
        case .same:
            return sendingWalletData.suggestedWallets
        case .swap(let receiveToken):
            return receivingWalletData?.suggestedWallets ?? []
        }
    }

    var additionalFieldType: SendDestinationAdditionalFieldType? {
        .type(for: receivedTokenType.tokenItem.blockchain)
    }

    private let sendingWalletData: SendingWalletData
    private var receivingWalletData: SendingWalletData?
    
    private let walletDataFactory: SendDestinationWalletDataFactory
    private var receivedTokenType: SendReceiveTokenType

    init(
        receivedTokenType: SendReceiveTokenType,
        sendingWalletData: SendingWalletData,
        walletDataFactory: SendDestinationWalletDataFactory
    ) {
        self.receivedTokenType = receivedTokenType
        self.sendingWalletData = sendingWalletData
        self.walletDataFactory = walletDataFactory
    }

    func update(receivedTokenType: SendReceiveTokenType) {
        self.receivedTokenType = receivedTokenType

        receivingWalletData = makeReceiveTokenWalletData(for: receivedTokenType.tokenItem)

        validator = makeValidator()
        addressResolver = makeAddressResolver()
        transactionHistoryProvider = makeSendDestinationTransactionHistoryProvider()
        parametersBuilder = makeTransactionParamsBuilder()
    }
}

// MARK: - Private

private extension SendDestinationInteractorDependenciesProvider {
    func makeValidator() -> SendDestinationValidator {
        let walletAddresses: [String] = switch receivedTokenType {
        case .same: sendingWalletData.walletAddresses
        case .swap: []
        }

        let addressService = AddressServiceFactory(blockchain: receivedTokenType.tokenItem.blockchain).makeAddressService()

        let validator = CommonSendDestinationValidator(
            walletAddresses: walletAddresses,
            addressService: addressService,
            supportsCompound: receivedTokenType.tokenItem.blockchain.supportsCompound
        )

        return validator
    }

    private func makeAddressResolver() -> AddressResolver? {
        AddressResolverFactoryProvider()
            .factory
            .makeAddressResolver(for: receivedTokenType.tokenItem.blockchain)
    }

    private func makeSendDestinationTransactionHistoryProvider() -> SendDestinationTransactionHistoryProvider {
        switch receivedTokenType {
        case .same:
            return sendingWalletData.destinationTransactionHistoryProvider
        case .swap(let receiveToken):
            return receivingWalletData?.destinationTransactionHistoryProvider ?? EmptySendDestinationTransactionHistoryProvider()
        }
    }

    private func makeTransactionParamsBuilder() -> TransactionParamsBuilder {
        TransactionParamsBuilder(blockchain: receivedTokenType.tokenItem.blockchain)
    }

    private func makeAnalyticsLogger() -> SendDestinationAnalyticsLogger {
        sendingWalletData.analyticsLogger
    }

    private func makeReceiveTokenWalletData(for tokenItem: TokenItem) -> SendingWalletData? {
        // Find wallet model and create new wallet data
        guard let walletModel = findWalletModel(for: tokenItem) else {
            return nil
        }

        let walletData = walletDataFactory.makeWalletData(
            walletModel: walletModel,
            analyticsLogger: sendingWalletData.analyticsLogger
        )

        return walletData
    }

    private func findWalletModel(for tokenItem: TokenItem) -> (any WalletModel)? {
        let targetNetworkId = tokenItem.blockchain.networkId

        return userWalletRepository.models
            .flatMap { userWalletModel -> [any WalletModel] in
                if FeatureProvider.isAvailable(.accounts) {
                    return AccountWalletModelsAggregator.walletModels(from: userWalletModel.accountModelsManager)
                } else {
                    // accounts_fixes_needed_none
                    return userWalletModel.walletModelsManager.walletModels
                }
            }
            .first { walletModel in
                walletModel.tokenItem.blockchain.networkId == targetNetworkId && walletModel.isMainToken
            }
    }
}

extension SendDestinationInteractorDependenciesProvider {
    struct SendingWalletData {
        let walletAddresses: [String]
        let suggestedWallets: [SendDestinationSuggestedWallet]
        let destinationTransactionHistoryProvider: SendDestinationTransactionHistoryProvider
        let analyticsLogger: SendDestinationAnalyticsLogger
    }
}
