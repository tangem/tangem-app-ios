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
    
    let coinContractAddress: String = "0xeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee"
    let isMainToken: Bool
    var amountType: Amount.AmountType
    var blockchainNetwork: BlockchainNetwork
    let exchangeFacade = ExchangeFacadeImpl(enableDebugMode: true)
    
    var tokenAddress: String {
        if amountType.isToken {
            return amountType.token!.contractAddress
        }
        return ""
    }
    
    var bag = Set<AnyCancellable>()
    
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
                let contractAddress: String
                if amountType.isToken {
                    contractAddress = amountType.token!.contractAddress
                } else {
                    contractAddress = coinContractAddress
                }
                
                let parameters = ApproveAllowanceParameters(tokenAddress: contractAddress, walletAddress: walletAddress)
                let allowanceResult = await exchangeFacade.allowance(blockchain: ExchangeBlockchain.convert(from: blockchainNetwork), allowanceParameters: parameters)

                switch allowanceResult {
                case .success(let allowanceDTO):
                    let decimalAllowance = Decimal(string: allowanceDTO.allowance)
                    
                    await MainActor.run {
                        isLock = (decimalAllowance ?? 0) == 0
                    }
                case .failure(let error):
                    print(error.localizedDescription)
                }
            }
        }
    }
}
