//
//  CommonExpressFeeProvider.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Combine
import Foundation
import TangemFoundation
import TangemExpress
import BlockchainSdk
import BigInt

class CommonExpressFeeProvider {
    private let feeLoader: any TokenFeeLoader
    private let sendingTokenItem: TokenItem
    private let sendingFeeTokenItem: TokenItem

    private let feesValueSubject: CurrentValueSubject<LoadingResult<[BSDKFee], any Error>, Never> = .init(.loading)

    private var feeLoadingTask: Task<Void, Never>?

    init(
        feeLoader: any TokenFeeLoader,
        sendingTokenItem: TokenItem,
        sendingFeeTokenItem: TokenItem
    ) {
        self.feeLoader = feeLoader
        self.sendingTokenItem = sendingTokenItem
        self.sendingFeeTokenItem = sendingFeeTokenItem
    }
}

// MARK: - StatableTokenFeeProvider

extension CommonExpressFeeProvider: StatableTokenFeeProvider {
    var supportingFeeOption: [FeeOption] {
        feeLoader.allowsFeeSelection ? [.market, .fast] : [.market]
    }

    var feeTokenItem: TokenItem { sendingFeeTokenItem }

    var loadingFees: LoadingResult<[BSDKFee], any Error> {
        feesValueSubject.value
    }

    var loadingFeesPublisher: AnyPublisher<LoadingResult<[BSDKFee], any Error>, Never> {
        feesValueSubject.eraseToAnyPublisher()
    }
}

// MARK: - TokenFeeProvider

extension CommonExpressFeeProvider: TokenFeeProvider {}

// MARK: - ExpressFeeProvider

extension CommonExpressFeeProvider: ExpressFeeProvider {
    func estimatedFee(amount: Decimal, option: ExpressFee.Option) async throws -> BSDKFee {
        try await loadTargetFee(targetOption: option) {
            try await feeLoader.estimatedFee(amount: amount)
        }
    }

    func estimatedFee(estimatedGasLimit: Int, option: ExpressFee.Option) async throws -> BSDKFee {
        try await loadTargetFee(targetOption: option) {
            let estimatedFee = try await feeLoader.asEthereumTokenFeeLoader().estimatedFee(estimatedGasLimit: estimatedGasLimit)
            return [estimatedFee]
        }
    }

    func getFee(amount: ExpressAmount, destination: String, option: ExpressFee.Option) async throws -> BSDKFee {
        switch (amount, sendingTokenItem.blockchain) {
        case (.transfer(let amount), _):
            return try await loadTargetFee(targetOption: option) {
                try await feeLoader.getFee(amount: amount, destination: destination)
            }

        case (.dex(_, _, let txData), .solana):
            guard let txData, let transactionData = Data(base64Encoded: txData) else {
                throw ExpressProviderError.transactionDataNotFound
            }

            return try await loadTargetFee(targetOption: option) {
                try await feeLoader.asSolanaTokenFeeLoader().getFee(compiledTransaction: transactionData)
            }

        case (.dex(_, let txValue, let txData), _):
            guard let txData = txData.map(Data.init(hexString:)) else {
                throw ExpressProviderError.transactionDataNotFound
            }

            let amount = makeAmount(amount: txValue, item: feeTokenItem)

            return try await loadTargetFee(targetOption: option) {
                try await feeLoader.asEthereumTokenFeeLoader().getFee(amount: amount, destination: destination, txData: txData)
            }
        }
    }
}

// MARK: - Private

extension CommonExpressFeeProvider {
    func makeAmount(amount: Decimal, item: TokenItem) -> Amount {
        Amount(with: item.blockchain, type: item.amountType, value: amount)
    }

    func loadTargetFee(targetOption: ExpressFee.Option, action: () async throws -> [BSDKFee]) async throws -> BSDKFee {
        if feesValueSubject.value.isFailure {
            feesValueSubject.send(.loading)
        }

        do {
            let loadedFees = try await action()
            feesValueSubject.send(.success(loadedFees))
        } catch {
            feesValueSubject.send(.failure(error))
        }

        let feeOption: FeeOption = switch targetOption {
        case .market: .market
        case .fast: .fast
        }

        guard let tokenFee = fees[feeOption] else {
            throw ExpressFeeProviderError.feeNotFound
        }

        return try tokenFee.value.get()
    }
}

//
// struct CommonExpressFeeProvider {
//    typealias FeesState = LoadingResult<[BSDKFee], any Error>
//
//    private let tokenItem: TokenItem
//    private let feeTokenItem: TokenItem
//    private let defaultFeeOptions: [FeeOption] = [.market, .fast]
//
//    private let feeLoader: any TokenFeeLoader
//    private let ethereumNetworkProvider: (any EthereumNetworkProvider)?
//
//    private let _fees: CurrentValueSubject<FeesState, Never> = .init(.loading)
//
//    init(
//        tokenItem: TokenItem,
//        feeTokenItem: TokenItem,
//        feeLoader: any TokenFeeLoader,
//        ethereumNetworkProvider: (any EthereumNetworkProvider)?
//    ) {
//        self.tokenItem = tokenItem
//        self.feeTokenItem = feeTokenItem
//        self.feeLoader = feeLoader
//        self.ethereumNetworkProvider = ethereumNetworkProvider
//    }
// }
//
//// MARK: - TokenFeeProvider
//
// extension CommonExpressFeeProvider: TokenFeeProvider {
//    var fees: [TokenFee] {
//        mapToFees(state: _fees.value)
//    }
//
//    var feesPublisher: AnyPublisher<[TokenFee], Never> {
//        _fees
//            .map { mapToFees(state: $0) }
//            .eraseToAnyPublisher()
//    }
//
//    func mapToFees(state: LoadingResult<[BSDKFee], any Error>) -> [TokenFee] {
//        switch state {
//        case .loading:
//            SendFeeConverter.mapToLoadingSendFees(options: defaultFeeOptions, feeTokenItem: feeTokenItem)
//        case .failure(let error):
//            SendFeeConverter.mapToFailureSendFees(options: defaultFeeOptions, feeTokenItem: feeTokenItem, error: error)
//        case .success(let loadedFees):
//            SendFeeConverter
//                .mapToSendFees(fees: loadedFees, feeTokenItem: feeTokenItem)
//                .filter { defaultFeeOptions.contains($0.option) }
//        }
//    }
// }
//
//// MARK: - ExpressFeeProvider
//
// extension CommonExpressFeeProvider: ExpressFeeProvider {
//    func estimatedFee(amount: Decimal) async throws -> Fee {
//        _fees.send(.loading)
//
//        let fees = try await feeLoader.estimatedFee(amount: amount)
//        _fees.send(.success(fees))
//
//        return try mapToExpressFee(fees: fees)
//    }
//
//    func estimatedFee(estimatedGasLimit: Int) async throws -> Fee {
//        guard let ethereumNetworkProvider = ethereumNetworkProvider else {
//            throw ExpressFeeProviderError.ethereumNetworkProviderNotFound
//        }
//
//        let parameters = try await ethereumNetworkProvider.getFee(
//            gasLimit: BigUInt(estimatedGasLimit),
//            supportsEIP1559: tokenItem.blockchain.supportsEIP1559
//        )
//
//        let amount = parameters.calculateFee(decimalValue: feeTokenItem.decimalValue)
//        return Fee(makeAmount(amount: amount, item: tokenItem))
//    }
//
//    func getFee(amount: ExpressAmount, destination: String) async throws -> Fee {
//        switch (amount, tokenItem.blockchain) {
//        case (.transfer(let amount), _):
//            _fees.send(.loading)
//            let fees = try await feeLoader.getFee(dataType: .plain(amount: amount, destination: destination))
//            _fees.send(.success(fees))
//            return try mapToExpressFee(fees: fees)
//        case (.dex(_, _, let txData), .solana):
//            guard let txData, let transactionData = Data(base64Encoded: txData) else {
//                throw ExpressProviderError.transactionDataNotFound
//            }
//            _fees.send(.loading)
//            let fees = try await feeLoader.getFee(dataType: .compiledTransaction(data: transactionData))
//            _fees.send(.success(fees))
//            return try mapToExpressFee(fees: fees)
//        case (.dex(_, let txValue, let txData), _):
//            guard let txData = txData.map(Data.init(hexString:)) else {
//                throw ExpressProviderError.transactionDataNotFound
//            }
//
//            // For DEX have to use `txData` when calculate fee
//            guard let ethereumNetworkProvider else {
//                throw ExpressFeeProviderError.ethereumNetworkProviderNotFound
//            }
//
//            _fees.send(.loading)
//            let amount = makeAmount(amount: txValue, item: feeTokenItem)
//            var fees = try await ethereumNetworkProvider.getFee(
//                destination: destination,
//                value: amount.encodedForSend,
//                data: txData
//            ).async()
//
//            // For EVM networks increase gas limit
//            fees = fees.map {
//                $0.increasingGasLimit(
//                    byPercents: EthereumFeeParametersConstants.defaultGasLimitIncreasePercent,
//                    blockchain: feeTokenItem.blockchain,
//                    decimalValue: feeTokenItem.decimalValue
//                )
//            }
//
//            _fees.send(.success(fees))
//            return try mapToExpressFee(fees: fees)
//        }
//    }
// }
//
//// MARK: - Private
//
// private extension CommonExpressFeeProvider {
//    func makeAmount(amount: Decimal, item: TokenItem) -> Amount {
//        Amount(with: item.blockchain, type: item.amountType, value: amount)
//    }
//
//    func mapToExpressFee(fees: [BSDKFee]) throws -> BSDKFee {
//        switch fees.count {
//        case 1:
//            return fees[0]
//        case 3 where tokenItem.blockchain.isUTXO:
//            return fees[1]
//        case 3:
//            return fees[1]
//        default:
//            throw ExpressFeeProviderError.feeNotFound
//        }
//    }
// }
