//
//  SendDestinationInteractorDependenciesProvider.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import BlockchainSdk

class SendDestinationInteractorDependenciesProvider {
    lazy var validator: SendDestinationValidator = makeValidator()
    lazy var addressResolver: AddressResolver? = makeAddressResolver()
    lazy var transactionHistoryProvider: SendDestinationTransactionHistoryProvider = makeSendDestinationTransactionHistoryProvider()
    lazy var parametersBuilder: TransactionParamsBuilder = makeTransactionParamsBuilder()
    lazy var analyticsLogger: SendDestinationAnalyticsLogger = makeAnalyticsLogger()

    var suggestedWallets: [SendDestinationSuggestedWallet] {
        currentWalletData.suggestedWallets
    }

    var additionalFieldType: SendDestinationAdditionalFieldType? {
        .type(for: receivedTokenType.tokenItem.blockchain)
    }

    private let sourceWalletData: SendingWalletData
    private let receiveTokenWalletDataProvider: ReceiveTokenWalletDataProvider?
    private var receivedTokenType: SendReceiveTokenType

    init(
        receivedTokenType: SendReceiveTokenType,
        sourceWalletData: SendingWalletData,
        receiveTokenWalletDataProvider: ReceiveTokenWalletDataProvider? = nil
    ) {
        self.receivedTokenType = receivedTokenType
        self.sourceWalletData = sourceWalletData
        self.receiveTokenWalletDataProvider = receiveTokenWalletDataProvider
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
    /// Returns the appropriate wallet data based on the current receive token type
    var currentWalletData: SendingWalletData {
        switch receivedTokenType {
        case .same:
            return sourceWalletData
        case .swap(let receiveToken):
            return receiveWalletData(for: receiveToken)
        }
    }

    func receiveWalletData(for receiveToken: SendReceiveToken) -> SendingWalletData {
        guard let walletData = receiveTokenWalletDataProvider?.walletData(for: receiveToken) else {
            return SendingWalletData(
                walletAddresses: [],
                suggestedWallets: [],
                destinationTransactionHistoryProvider: EmptySendDestinationTransactionHistoryProvider(),
                analyticsLogger: sourceWalletData.analyticsLogger
            )
        }

        return walletData
    }

    func makeValidator() -> SendDestinationValidator {
        let walletAddresses = currentWalletData.walletAddresses

        let addressService = AddressServiceFactory(blockchain: receivedTokenType.tokenItem.blockchain).makeAddressService()

        let validator = CommonSendDestinationValidator(
            walletAddresses: walletAddresses,
            addressService: addressService,
            allowSameAddressTransaction: receivedTokenType.tokenItem.blockchain.supportsCompound || receivedTokenType.isSwap
        )

        return validator
    }

    private func makeAddressResolver() -> AddressResolver? {
        AddressResolverFactoryProvider()
            .factory
            .makeAddressResolver(for: receivedTokenType.tokenItem.blockchain)
    }

    private func makeSendDestinationTransactionHistoryProvider() -> SendDestinationTransactionHistoryProvider {
        currentWalletData.destinationTransactionHistoryProvider
    }

    private func makeTransactionParamsBuilder() -> TransactionParamsBuilder {
        TransactionParamsBuilder(blockchain: receivedTokenType.tokenItem.blockchain)
    }

    private func makeAnalyticsLogger() -> SendDestinationAnalyticsLogger {
        sourceWalletData.analyticsLogger
    }
}

// MARK: - Types

extension SendDestinationInteractorDependenciesProvider {
    struct SendingWalletDataInput {
        let walletAddresses: [String]
        let suggestedWallets: [SendDestinationSuggestedWallet]
        let walletModelHistoryUpdater: any WalletModelHistoryUpdater
    }

    struct SendingWalletData {
        let walletAddresses: [String]
        let suggestedWallets: [SendDestinationSuggestedWallet]
        let destinationTransactionHistoryProvider: SendDestinationTransactionHistoryProvider
        let analyticsLogger: SendDestinationAnalyticsLogger
    }

    /// Protocol for providing wallet data for receive tokens in swap flows
    protocol ReceiveTokenWalletDataProvider {
        func walletData(for receiveToken: SendReceiveToken) -> SendingWalletData?
    }
}
