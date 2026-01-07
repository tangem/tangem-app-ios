//
//  SendFeeProviderInput.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import Foundation

final class CommonSendFeeProvider {
    private let feeProvider: TokenFeeProvider
    private let tokenItem: TokenItem
    private let defaultFeeOptions: [FeeOption]

    private let _cryptoAmount: CurrentValueSubject<Decimal?, Never> = .init(nil)
    private let _destination: CurrentValueSubject<String?, Never> = .init(nil)

    private var cryptoAmountSubscription: AnyCancellable?
    private var destinationAddressSubscription: AnyCancellable?

    init(
        input: any SendFeeProviderInput,
        feeProvider: TokenFeeProvider,
        tokenItem: TokenItem,
        defaultFeeOptions: [FeeOption]
    ) {
        self.feeProvider = feeProvider
        self.tokenItem = tokenItem
        self.defaultFeeOptions = defaultFeeOptions

        bind(input: input)
    }
}

// MARK: - SendFeeProvider

extension CommonSendFeeProvider: SendFeeProvider {
    var fees: [TokenFee] {
        feeProvider.fees
    }

    var feesPublisher: AnyPublisher<[TokenFee], Never> {
        feeProvider.feesPublisher
    }

    func updateFees() {
        guard let amount = _cryptoAmount.value, let destination = _destination.value else {
            assertionFailure("SendFeeProvider is not ready to update fees")
            return
        }

        let request = TokenFeeProviderFeeRequest(amount: amount, destination: destination, tokenItem: tokenItem)
        feeProvider.reloadFees(request: request)
    }
}

// MARK: - Private

private extension CommonSendFeeProvider {
    func bind(input: any SendFeeProviderInput) {
        cryptoAmountSubscription = input.cryptoAmountPublisher
            .withWeakCaptureOf(self)
            .sink { provider, amount in
                provider._cryptoAmount.send(amount)
            }

        destinationAddressSubscription = input.destinationAddressPublisher
            .withWeakCaptureOf(self)
            .sink { provider, destination in
                provider._destination.send(destination)
            }
    }
}
