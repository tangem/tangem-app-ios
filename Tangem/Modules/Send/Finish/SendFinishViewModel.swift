//
//  SendFinishViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI
import Combine

protocol SendFinishViewModelInput: AnyObject {
    var amountTextBinding: Binding<String> { get }
    var destinationTextBinding: Binding<String> { get }
    var feeTextBinding: Binding<String> { get }
    var transactionURL: AnyPublisher<URL?, Never> { get }
    var transactionTime: AnyPublisher<Date?, Never> { get }
}

protocol SendFinishRoutable: AnyObject {
    func explore(url: URL)
    func share(url: URL)
    func close()
}

class SendFinishViewModel: ObservableObject {
    let amountText: String
    let destinationText: String
    let feeText: String

    @Published var transactionTime: String?

    weak var router: SendFinishRoutable?

    private var bag: Set<AnyCancellable> = []
    private var transactionURL: URL?

    init(input: SendFinishViewModelInput) {
        amountText = input.amountTextBinding.wrappedValue
        destinationText = input.destinationTextBinding.wrappedValue
        feeText = input.feeTextBinding.wrappedValue

        bind(from: input)
    }

    func explore() {
        guard let transactionURL else { return }
        router?.explore(url: transactionURL)
    }

    func share() {
        guard let transactionURL else { return }
        router?.share(url: transactionURL)
    }

    func close() {
        router?.close()
    }

    private func bind(from input: SendFinishViewModelInput) {
        input.transactionURL
            .assign(to: \.transactionURL, on: self, ownership: .weak)
            .store(in: &bag)

        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .short
        input.transactionTime
            .compactMap { transactionTime in
                guard let transactionTime else { return nil }
                return formatter.string(from: transactionTime)
            }
            .assign(to: \.transactionTime, on: self, ownership: .weak)
            .store(in: &bag)
    }
}
