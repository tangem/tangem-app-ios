//
//  SendSummaryInteractor.swift
//  Tangem
//
//  Created by Sergey Balashov on 24.06.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import BlockchainSdk

protocol SendSummaryInput: AnyObject {
    var transactionPublisher: AnyPublisher<BlockchainSdk.Transaction?, Never> { get }
}

protocol SendSummaryOutput: AnyObject {}

protocol SendSummaryInteractor: AnyObject {
    func setup(input: SendSummaryInput, output: SendSummaryOutput)

    var transactionDescription: AnyPublisher<String?, Never> { get }
}

class CommonSendSummaryInteractor {
    private let sendTransactionSender: SendTransactionSender
    private let descriptionBuilder: SendTransactionSummaryDescriptionBuilder

    private let _transactionDescription: CurrentValueSubject<String?, Never> = .init(.none)
    private var bag: Set<AnyCancellable> = []

    init(
        sendTransactionSender: SendTransactionSender,
        descriptionBuilder: SendTransactionSummaryDescriptionBuilder
    ) {
        self.sendTransactionSender = sendTransactionSender
        self.descriptionBuilder = descriptionBuilder
    }

    private func bind(input: any SendSummaryInput) {
        input
            .transactionPublisher
            .withWeakCaptureOf(self)
            .sink { interactor, transaction in
                let description = transaction.flatMap { transaction in
                    interactor.descriptionBuilder.makeDescription(
                        amount: transaction.amount.value,
                        fee: transaction.fee.amount.value
                    )
                }

                interactor._transactionDescription.send(description)
            }
            .store(in: &bag)
    }
}

extension CommonSendSummaryInteractor: SendSummaryInteractor {
    func setup(input: any SendSummaryInput, output: any SendSummaryOutput) {
        bind(input: input)
    }

    var isSending: AnyPublisher<Bool, Never> {
        sendTransactionSender.isSending
    }

    var transactionDescription: AnyPublisher<String?, Never> {
        return _transactionDescription.eraseToAnyPublisher()
    }
}
