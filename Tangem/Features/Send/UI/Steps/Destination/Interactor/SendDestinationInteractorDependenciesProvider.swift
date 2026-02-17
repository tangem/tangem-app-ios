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
        .type(for: tokenItem.blockchain)
    }

    private let initialSourceToken: SendSourceToken
    private let sourceWalletData: SendingWalletData
    private let receiveTokenWalletDataProvider: ReceiveTokenWalletDataProvider?
    private var receivedToken: SendReceiveToken?

    private var tokenItem: TokenItem {
        receivedToken?.tokenItem ?? initialSourceToken.tokenItem
    }

    init(
        initialSourceToken: SendSourceToken,
        receivedToken: SendReceiveToken?,
        sourceWalletData: SendingWalletData,
        receiveTokenWalletDataProvider: ReceiveTokenWalletDataProvider? = nil
    ) {
        self.initialSourceToken = initialSourceToken
        self.receivedToken = receivedToken
        self.sourceWalletData = sourceWalletData
        self.receiveTokenWalletDataProvider = receiveTokenWalletDataProvider
    }

    func update(receivedToken: SendReceiveToken?) {
        self.receivedToken = receivedToken

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
        switch receivedToken {
        case .none:
            return sourceWalletData
        case .some(let receiveToken):
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

        let addressService = AddressServiceFactory(blockchain: tokenItem.blockchain).makeAddressService()

        let validator = CommonSendDestinationValidator(
            walletAddresses: walletAddresses,
            addressService: addressService,
            allowSameAddressTransaction: tokenItem.blockchain.supportsCompound || receivedToken != nil
        )

        return validator
    }

    private func makeAddressResolver() -> AddressResolver? {
        AddressResolverFactoryProvider()
            .factory
            .makeAddressResolver(for: tokenItem.blockchain)
    }

    private func makeSendDestinationTransactionHistoryProvider() -> SendDestinationTransactionHistoryProvider {
        currentWalletData.destinationTransactionHistoryProvider
    }

    private func makeTransactionParamsBuilder() -> TransactionParamsBuilder {
        TransactionParamsBuilder(blockchain: tokenItem.blockchain)
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
