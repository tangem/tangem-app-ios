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

struct CommonExpressFeeProvider {
    typealias FeesState = LoadingResult<[BSDKFee], any Error>

    private let tokenItem: TokenItem
    private let feeTokenItem: TokenItem
    private let defaultFeeOptions: [FeeOption] = [.market, .fast]

    private let feeLoader: any TokenFeeLoader
    private let ethereumNetworkProvider: (any EthereumNetworkProvider)?

    private let _fees: CurrentValueSubject<FeesState, Never> = .init(.loading)

    init(
        tokenItem: TokenItem,
        feeTokenItem: TokenItem,
        feeLoader: any TokenFeeLoader,
        ethereumNetworkProvider: (any EthereumNetworkProvider)?
    ) {
        self.tokenItem = tokenItem
        self.feeTokenItem = feeTokenItem
        self.feeLoader = feeLoader
        self.ethereumNetworkProvider = ethereumNetworkProvider
    }
}

// MARK: - TokenFeeProvider

extension CommonExpressFeeProvider: TokenFeeProvider {
    var fees: [TokenFee] {
        mapToFees(state: _fees.value)
    }

    var feesPublisher: AnyPublisher<[TokenFee], Never> {
        _fees
            .map { mapToFees(state: $0) }
            .eraseToAnyPublisher()
    }

    func mapToFees(state: LoadingResult<[BSDKFee], any Error>) -> [TokenFee] {
        switch state {
        case .loading:
            SendFeeConverter.mapToLoadingSendFees(options: defaultFeeOptions, feeTokenItem: feeTokenItem)
        case .failure(let error):
            SendFeeConverter.mapToFailureSendFees(options: defaultFeeOptions, feeTokenItem: feeTokenItem, error: error)
        case .success(let loadedFees):
            SendFeeConverter
                .mapToSendFees(fees: loadedFees, feeTokenItem: feeTokenItem)
                .filter { defaultFeeOptions.contains($0.option) }
        }
    }
}

// MARK: - ExpressFeeProvider

extension CommonExpressFeeProvider: ExpressFeeProvider {
    func estimatedFee(amount: Decimal) async throws -> Fee {
        _fees.send(.loading)

        let fees = try await feeLoader.estimatedFee(amount: amount)
        _fees.send(.success(fees))

        return try mapToExpressFee(fees: fees)
    }

    func estimatedFee(estimatedGasLimit: Int) async throws -> Fee {
        guard let ethereumNetworkProvider = ethereumNetworkProvider else {
            throw ExpressFeeProviderError.ethereumNetworkProviderNotFound
        }

        let parameters = try await ethereumNetworkProvider.getFee(
            gasLimit: BigUInt(estimatedGasLimit),
            supportsEIP1559: tokenItem.blockchain.supportsEIP1559
        )

        let amount = parameters.calculateFee(decimalValue: feeTokenItem.decimalValue)
        return Fee(makeAmount(amount: amount, item: tokenItem))
    }

    func getFee(amount: ExpressAmount, destination: String) async throws -> Fee {
        switch (amount, tokenItem.blockchain) {
        case (.transfer(let amount), _):
            _fees.send(.loading)
            let fees = try await feeLoader.getFee(dataType: .plain(amount: amount, destination: destination))
            _fees.send(.success(fees))
            return try mapToExpressFee(fees: fees)
        case (.dex(_, _, let txData), .solana):
            guard let txData, let transactionData = Data(base64Encoded: txData) else {
                throw ExpressProviderError.transactionDataNotFound
            }
            _fees.send(.loading)
            let fees = try await feeLoader.getFee(dataType: .compiledTransaction(data: transactionData))
            _fees.send(.success(fees))
            return try mapToExpressFee(fees: fees)
        case (.dex(_, let txValue, let txData), _):
            guard let txData = txData.map(Data.init(hexString:)) else {
                throw ExpressProviderError.transactionDataNotFound
            }

            // For DEX have to use `txData` when calculate fee
            guard let ethereumNetworkProvider else {
                throw ExpressFeeProviderError.ethereumNetworkProviderNotFound
            }

            _fees.send(.loading)
            let amount = makeAmount(amount: txValue, item: feeTokenItem)
            var fees = try await ethereumNetworkProvider.getFee(
                destination: destination,
                value: amount.encodedForSend,
                data: txData
            ).async()

            // For EVM networks increase gas limit
            fees = fees.map {
                $0.increasingGasLimit(
                    byPercents: EthereumFeeParametersConstants.defaultGasLimitIncreasePercent,
                    blockchain: feeTokenItem.blockchain,
                    decimalValue: feeTokenItem.decimalValue
                )
            }

            _fees.send(.success(fees))
            return try mapToExpressFee(fees: fees)
        }
    }
}

// MARK: - Private

private extension CommonExpressFeeProvider {
    func makeAmount(amount: Decimal, item: TokenItem) -> Amount {
        Amount(with: item.blockchain, type: item.amountType, value: amount)
    }

    func mapToExpressFee(fees: [BSDKFee]) throws -> BSDKFee {
        switch fees.count {
        case 1:
            return fees[0]
        case 3 where tokenItem.blockchain.isUTXO:
            return fees[1]
        case 3:
            return fees[1]
        default:
            throw ExpressFeeProviderError.feeNotFound
        }
    }
}
