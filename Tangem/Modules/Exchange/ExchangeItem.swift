//
//  ExchangeItem.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk
import Combine

class ExchangeItem: Identifiable {
    let id: UUID = UUID()
    let isMainToken: Bool

    var allowance: Decimal = 0

    @Published var isLocked: Bool = false
    @Published var amountText: String = ""

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
        blockchainNetwork: BlockchainNetwork
    ) {
        self.isMainToken = isMainToken
        self.amount = amount
        self.blockchainNetwork = blockchainNetwork

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
}
