//
//  SendDestinationInteractorDependenciesProvider.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Combine
import CombineExt
import BlockchainSdk
import TangemFoundation

class SendDestinationInteractorDependenciesProvider {
    lazy var validator: SendDestinationValidator = makeValidator()
    lazy var addressResolver: AddressResolver? = makeAddressResolver()
    lazy var transactionHistoryProvider: SendDestinationTransactionHistoryProvider = makeSendDestinationTransactionHistoryProvider()
    lazy var parametersBuilder: TransactionParamsBuilder = makeTransactionParamsBuilder()
    lazy var addressBooksProvider: (any AddressBooksProvider)? = makeAddressBooksProvider()
    let analyticsLogger: SendDestinationAnalyticsLogger

    var suggestedWallets: [SendDestinationSuggestedWallet] {
        currentWalletData.suggestedWallets
    }

    var additionalFieldType: SendDestinationAdditionalFieldType? {
        .type(for: tokenItem.blockchain)
    }

    /// Address-book contacts for the current network — already de-duplicated by address across wallets by
    /// `NetworkAddressBooksProvider` — paired with their source wallet name for the breadcrumb. Empty when
    /// the feature is off.
    var addressBookContactsPublisher: AnyPublisher<[SendDestinationAddressBookContact], Never> {
        guard let addressBooksProvider else {
            return .just(output: [])
        }

        return addressBooksProvider.addressBooksPublisher
            .flatMapLatest { books -> AnyPublisher<[SendDestinationAddressBookContact], Never> in
                guard books.isNotEmpty else {
                    return .just(output: [])
                }

                return books.map { book in
                    book.addressBookPublisher.map { contacts in
                        contacts.map {
                            SendDestinationAddressBookContact(
                                contact: $0,
                                walletName: book.wallet.name
                            )
                        }
                    }
                }
                .combineLatest()
                .map { $0.flattened() }
                .eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
    }

    private let sourceToken: SendSourceToken
    private let destinationWalletDataProvider: SendDestinationWalletDataProvider
    private var receivedToken: SendReceiveToken?

    private var tokenItem: TokenItem {
        receivedToken?.tokenItem ?? sourceToken.tokenItem
    }

    init(
        sourceToken: SendSourceToken,
        receivedToken: SendReceiveToken?,
        analyticsLogger: SendDestinationAnalyticsLogger,
        destinationWalletDataProvider: SendDestinationWalletDataProvider
    ) {
        self.sourceToken = sourceToken
        self.receivedToken = receivedToken
        self.analyticsLogger = analyticsLogger
        self.destinationWalletDataProvider = destinationWalletDataProvider
    }

    func update(receivedToken: SendReceiveToken?) {
        self.receivedToken = receivedToken

        validator = makeValidator()
        addressResolver = makeAddressResolver()
        transactionHistoryProvider = makeSendDestinationTransactionHistoryProvider()
        parametersBuilder = makeTransactionParamsBuilder()
        addressBooksProvider = makeAddressBooksProvider()
    }
}

// MARK: - Private

private extension SendDestinationInteractorDependenciesProvider {
    /// Returns the appropriate wallet data based on the current receive token type
    var currentWalletData: SendingWalletData {
        switch receivedToken {
        case .none:
            return destinationWalletDataProvider.sendWalletData() ?? .empty
        case .some(let receiveToken):
            return destinationWalletDataProvider.swapWalletData(for: receiveToken.tokenItem) ?? .empty
        }
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

    /// Vends address-book contacts scoped to the current destination network when the feature is enabled.
    private func makeAddressBooksProvider() -> (any AddressBooksProvider)? {
        guard FeatureProvider.isAvailable(.addressBook) else {
            return nil
        }

        return NetworkAddressBooksProvider(
            networkId: AddressBookNetworkID(tokenItem.blockchain.networkId),
            currentWalletId: sourceToken.userWalletInfo.id
        )
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

    protocol SendDestinationWalletDataProvider {
        func sendWalletData() -> SendDestinationInteractorDependenciesProvider.SendingWalletData?

        func swapWalletData(
            for tokenItem: TokenItem
        ) -> SendDestinationInteractorDependenciesProvider.SendingWalletData?
    }
}
