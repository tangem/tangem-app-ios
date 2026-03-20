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
    let analyticsLogger: SendDestinationAnalyticsLogger

    var suggestedWallets: [SendDestinationSuggestedWallet] {
        currentWalletData.suggestedWallets
    }

    var additionalFieldType: SendDestinationAdditionalFieldType? {
        .type(for: tokenItem.blockchain)
    }

    private let sourceToken: SendSourceToken
    private let receiveTokenWalletDataProvider: ReceiveTokenWalletDataProvider
    private var receivedToken: SendReceiveToken?

    private var tokenItem: TokenItem {
        receivedToken?.tokenItem ?? sourceToken.tokenItem
    }

    init(
        sourceToken: SendSourceToken,
        receivedToken: SendReceiveToken?,
        analyticsLogger: SendDestinationAnalyticsLogger,
        receiveTokenWalletDataProvider: ReceiveTokenWalletDataProvider
    ) {
        self.sourceToken = sourceToken
        self.receivedToken = receivedToken
        self.analyticsLogger = analyticsLogger
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
            return walletData(for: sourceToken.tokenItem)
        case .some(let receiveToken):
            return swapWalletData(for: receiveToken)
        }
    }

    /// Composes `SendingWalletData` for the swap (Express) flow.
    ///
    /// In a swap, the source and receive tokens may be on different networks,
    /// and the receive token's destination wallet could be in any user wallet.
    /// Therefore:
    /// - `walletAddresses` comes from the **source** token's wallet model,
    ///   so the validator can detect "sending to yourself" against the source wallet
    /// - `suggestedWallets` aggregates wallets across **all** user wallets and accounts
    ///   for the receive token's network, giving the user the full choice of destinations
    /// - `destinationTransactionHistoryProvider` is an empty stub because we cannot
    ///   determine which user wallet the receive token belongs to at this point
    func swapWalletData(for receiveToken: SendReceiveToken) -> SendingWalletData {
        let sourceWalletData = walletData(for: sourceToken.tokenItem)
        let receiveSwapData = receiveTokenWalletDataProvider.swapWalletData(for: receiveToken.tokenItem)

        return SendingWalletData(
            walletAddresses: sourceWalletData.walletAddresses,
            suggestedWallets: receiveSwapData.suggestedWallets,
            destinationTransactionHistoryProvider: receiveSwapData.destinationTransactionHistoryProvider
        )
    }

    func walletData(for tokenItem: TokenItem) -> SendingWalletData {
        guard let walletData = receiveTokenWalletDataProvider.walletData(
            for: tokenItem,
            inUserWalletWithInfo: sourceToken.userWalletInfo
        ) else {
            return .empty
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
}

// MARK: - Types

extension SendDestinationInteractorDependenciesProvider {
    struct SendingWalletData {
        static let empty: SendingWalletData = .init(
            walletAddresses: [],
            suggestedWallets: [],
            destinationTransactionHistoryProvider: EmptySendDestinationTransactionHistoryProvider()
        )

        let walletAddresses: [String]
        let suggestedWallets: [SendDestinationSuggestedWallet]
        let destinationTransactionHistoryProvider: SendDestinationTransactionHistoryProvider
    }

    /// Protocol for providing wallet data for receive tokens in swap flows
    protocol ReceiveTokenWalletDataProvider {
        func walletData(
            for tokenItem: TokenItem,
            inUserWalletWithInfo userWalletInfo: UserWalletInfo
        ) -> SendDestinationInteractorDependenciesProvider.SendingWalletData?

        func swapWalletData(
            for tokenItem: TokenItem
        ) -> SendDestinationInteractorDependenciesProvider.SendingWalletData
    }
}
