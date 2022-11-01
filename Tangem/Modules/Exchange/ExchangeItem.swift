//
//  ExchangeItem.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk
import ExchangeSdk
import Combine

class ExchangeItem: Identifiable {
    let id: UUID = UUID()

    @Published var isLocked: Bool = false
    @Published var amount: String = ""

    var allowance: Decimal = 0

    private let isMainToken: Bool
    private let exchangeService: ExchangeServiceProtocol
    private let coinContractAddress: String = "0xeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee"

    private var amountType: Amount.AmountType
    private var blockchainNetwork: BlockchainNetwork
    private var bag = Set<AnyCancellable>()

    var tokenAddress: String {
        amountType.token?.contractAddress ?? coinContractAddress
    }

    init(
        isMainToken: Bool,
        amountType: Amount.AmountType,
        blockchainNetwork: BlockchainNetwork,
        exchangeService: ExchangeServiceProtocol
    ) {
        self.isMainToken = isMainToken
        self.amountType = amountType
        self.blockchainNetwork = blockchainNetwork
        self.exchangeService = exchangeService

        bind()
    }

    func bind() {
        $amount
            .sink { [unowned self] value in
                let filtered = value
                    .filter { "0123456789.".contains($0) }
                    .reduce("") { partialResult, character in
                        var newPartialResult = partialResult
                        if newPartialResult.isEmpty && "\(character)" == "." {
                            newPartialResult = "0."
                        } else {
                            newPartialResult += String(character)
                        }
                        return newPartialResult
                    }

                if filtered != value {
                    self.amount = filtered
                }
            }
            .store(in: &bag)
    }

    func fetchApprove(walletAddress: String) {
        guard !isMainToken else { return }

        Task {
            let contractAddress: String = amountType.isToken ? amountType.token!.contractAddress : coinContractAddress
            let parameters = ApproveAllowanceParameters(tokenAddress: contractAddress, walletAddress: walletAddress)

            let allowanceResult = await exchangeService.allowance(blockchain: ExchangeBlockchain.convert(from: blockchainNetwork),
                                                                  allowanceParameters: parameters)

            switch allowanceResult {
            case .success(let allowanceInfo):
                let decimalAllowance = Decimal(string: allowanceInfo.allowance) ?? 0
                allowance = decimalAllowance

                await MainActor.run {
                    isLocked = allowance == 0
                }
            case .failure(let error):
                print(error.localizedDescription)
            }
        }
    }

    func approveTxData() async throws -> ApprovedTransactionData {
        return try await withCheckedThrowingContinuation({ continuation in
            Task {
                let parameters = ApproveTransactionParameters(tokenAddress: tokenAddress, amount: .infinite)
                let txResponse = await exchangeService.approveTransaction(blockchain: ExchangeBlockchain.convert(from: blockchainNetwork), approveTransactionParameters: parameters)

                switch txResponse {
                case .success(let approveTxData):
                    continuation.resume(returning: approveTxData)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        })
    }
}
