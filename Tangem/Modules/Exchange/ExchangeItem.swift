//
//  ExchangeItem.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk
import Exchanger
import Combine

class ExchangeItem: Identifiable {
    var id: UUID = UUID()

    @Published var isLock: Bool = false
    @Published var amount: String = ""

    var allowance: Decimal = 0
    
    private let isMainToken: Bool
    private let exchangeFacade = ExchangeFacadeImpl(enableDebugMode: true)
    private let coinContractAddress: String = "0xeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee"

    private var amountType: Amount.AmountType
    private var blockchainNetwork: BlockchainNetwork
    private var bag = Set<AnyCancellable>()

    var tokenAddress: String {
        if amountType.isToken {
            return amountType.token!.contractAddress
        }
        return coinContractAddress
    }

    init(
        isMainToken: Bool,
        amountType: Amount.AmountType,
        blockchainNetwork: BlockchainNetwork
    ) {
        self.isLock = false
        self.isMainToken = isMainToken
        self.amountType = amountType
        self.blockchainNetwork = blockchainNetwork

        bind()
    }

    func bind() {
        $amount
            .sink { [unowned self] value in
                let filtered = value.filter { "0123456789".contains($0) }
                if filtered != value {
                    self.amount = filtered
                }
            }
            .store(in: &bag)
    }

    func fetchApprove(walletAddress: String) {
        if !isMainToken {
            Task {
                let contractAddress: String = amountType.isToken ? amountType.token!.contractAddress : coinContractAddress
                let parameters = ApproveAllowanceParameters(tokenAddress: contractAddress, walletAddress: walletAddress)

                let allowanceResult = await exchangeFacade.allowance(blockchain: ExchangeBlockchain.convert(from: blockchainNetwork),
                                                                     allowanceParameters: parameters)

                switch allowanceResult {
                case .success(let allowanceDTO):
                    let decimalAllowance = Decimal(string: allowanceDTO.allowance)
                    allowance = decimalAllowance ?? 0
                    
                    await MainActor.run {
                        isLock = (decimalAllowance ?? 0) == 0
                    }
                case .failure(let error):
                    print(error.localizedDescription)
                }
            }
        }
    }

    func approveTxData() async throws -> ApproveTransactionDTO {
        return try await withCheckedThrowingContinuation({ continuation in
            Task {
                let parameters = ApproveTransactionParameters(tokenAddress: tokenAddress, amount: .infinite)
                let txResponse = await exchangeFacade.approveTransaction(blockchain: ExchangeBlockchain.convert(from: blockchainNetwork), approveTransactionParameters: parameters)

                switch txResponse {
                case .success(let approveDTO):
                    continuation.resume(returning: approveDTO)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        })
    }
}
