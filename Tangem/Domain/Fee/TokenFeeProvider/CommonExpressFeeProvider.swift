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

enum ExpressFeeProviderError: Error {
    case feeNotFound
}
