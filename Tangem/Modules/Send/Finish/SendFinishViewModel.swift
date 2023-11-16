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
    var transactionURL: URL? { get }
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

    weak var router: SendFinishRoutable?

    private var bag: Set<AnyCancellable> = []

    private let transactionURL: URL?

    init(input: SendFinishViewModelInput) {
        amountText = input.amountTextBinding.wrappedValue
        destinationText = input.destinationTextBinding.wrappedValue
        feeText = input.feeTextBinding.wrappedValue

        transactionURL = input.transactionURL
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
}
