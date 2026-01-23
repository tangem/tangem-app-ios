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
            return makeSuggestedWalletsForReceiveToken(receiveToken)
        }
    }

    var additionalFieldType: SendDestinationAdditionalFieldType? {
        .type(for: receivedTokenType.tokenItem.blockchain)
    }

    private let sendingWalletData: SendingWalletData
    private var receivedTokenType: SendReceiveTokenType

    init(
        receivedTokenType: SendReceiveTokenType,
        sendingWalletData: SendingWalletData
    ) {
        self.receivedTokenType = receivedTokenType
        self.sendingWalletData = sendingWalletData
    }

    func update(receivedTokenType: SendReceiveTokenType) {
        self.receivedTokenType = receivedTokenType

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
            return makeTransactionHistoryProviderForReceiveToken(receiveToken)
        }
    }

    private func makeTransactionParamsBuilder() -> TransactionParamsBuilder {
        TransactionParamsBuilder(blockchain: receivedTokenType.tokenItem.blockchain)
    }

    private func makeAnalyticsLogger() -> SendDestinationAnalyticsLogger {
        sendingWalletData.analyticsLogger
    }

    private func makeSuggestedWalletsForReceiveToken(_ receiveToken: SendReceiveToken) -> [SendDestinationSuggestedWallet] {
        guard let walletModel = findWalletModel(for: receiveToken.tokenItem) else {
            return []
        }

        return SendSuggestedWalletsFactory().makeSuggestedWallets(walletModel: walletModel)
    }

    private func makeTransactionHistoryProviderForReceiveToken(_ receiveToken: SendReceiveToken) -> SendDestinationTransactionHistoryProvider {
        guard let walletModel = findWalletModel(for: receiveToken.tokenItem) else {
            return EmptySendDestinationTransactionHistoryProvider()
        }

        let walletAddresses = walletModel.addresses.map(\.value)
        return CommonSendDestinationTransactionHistoryProvider(
            transactionHistoryUpdater: walletModel,
            transactionHistoryMapper: TransactionHistoryMapper(
                currencySymbol: receiveToken.tokenItem.currencySymbol,
                walletAddresses: walletAddresses,
                showSign: false,
                isToken: receiveToken.tokenItem.isToken
            )
        )
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
