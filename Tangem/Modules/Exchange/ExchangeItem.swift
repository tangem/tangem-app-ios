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
    @Published var amountText: String = ""

    var allowance: Decimal = 0

    private let isMainToken: Bool
    private let exchangeService: ExchangeServiceProtocol
    private let coinContractAddress: String = "0xeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee"

    private var amount: Amount
    private var blockchainNetwork: BlockchainNetwork
    private var bag = Set<AnyCancellable>()

    var tokenAddress: String {
        amount.type.token?.contractAddress ?? coinContractAddress
    }

    init(
        isMainToken: Bool,
        amount: Amount,
        blockchainNetwork: BlockchainNetwork,
        exchangeService: ExchangeServiceProtocol
    ) {
        self.isMainToken = isMainToken
        self.amount = amount
        self.blockchainNetwork = blockchainNetwork
        self.exchangeService = exchangeService

        bind()
    }

    func bind() {
        $amountText
            .sink { [unowned self] value in
                let decimals = Decimal(string: value.replacingOccurrences(of: ",", with: ".")) ?? 0
                let newAmount = Amount(with: amount, value: decimals).value
                let formatter = NumberFormatter()
                formatter.numberStyle = .none

                let newValue = formatter.string(for: newAmount) ?? ""

                if newValue != value {
                    self.amountText = newValue
                }
            }
            .store(in: &bag)
    }

    func fetchApprove(walletAddress: String) {
        guard !isMainToken else { return }

        Task {
            let contractAddress: String = amount.type.isToken ? amount.type.token!.contractAddress : coinContractAddress
            let parameters = ApproveAllowanceParameters(tokenAddress: contractAddress, walletAddress: walletAddress)

            let allowanceResult = await exchangeService.allowance(blockchain: ExchangeBlockchain.convert(from: blockchainNetwork),
                                                                  allowanceParameters: parameters)

            switch allowanceResult {
            case .success(let allowanceInfo):
                allowance = Decimal(string: allowanceInfo.allowance) ?? 0

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
