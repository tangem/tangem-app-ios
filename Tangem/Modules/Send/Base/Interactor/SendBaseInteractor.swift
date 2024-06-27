//
//  SendBaseInteractor.swift
//  Tangem
//
//  Created by Sergey Balashov on 27.06.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine

protocol SendBaseInteractor {
    var isLoading: AnyPublisher<Bool, Never> { get }
//    var performNext: AnyPublisher<Void, Never> { get }

    func send() -> AnyPublisher<SendTransactionSentResult, Never>
}

class CommonSendBaseInteractor {
    private weak var input: SendBaseInput?
    private weak var output: SendBaseOutput?

    private let sendDestinationInput: SendDestinationInput

    init(
        input: SendBaseInput,
        output: SendBaseOutput,
        sendDestinationInput: SendDestinationInput
    ) {
        self.input = input
        self.output = output

        self.sendDestinationInput = sendDestinationInput
    }
}

extension CommonSendBaseInteractor: SendBaseInteractor {
    var isLoading: AnyPublisher<Bool, Never> {
        input?.isLoading ?? .just(output: false)
    }

    /*
     var performNext: AnyPublisher<Void, Never> {
         sendDestinationInput
             .destinationPublisher()
             .filter { destination in
                 switch destination.source {
                 case .myWallet, .recentAddress:
                     return true
                 default:
                     return false
                 }
             }
             .mapToVoid()
             .eraseToAnyPublisher()
     }
      */

    func send() -> AnyPublisher<SendTransactionSentResult, Never> {
        output?.sendTransaction() ?? .just(output: .init(url: nil))
    }
}
