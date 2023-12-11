//
//  SendFeeViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI
import Combine
import BlockchainSdk

protocol SendFeeViewModelInput {
    var selectedFeeOption: FeeOption { get }
    var feeOptions: [FeeOption] { get }
    var feeValues: AnyPublisher<[FeeOption: LoadingValue<Fee>], Never> { get }
    var blockchain: Blockchain { get }
    var tokenItem: TokenItem { get }
}

protocol SendFeeViewModelDelegate: AnyObject {
    func didSelectFeeOption(_ feeOption: FeeOption)
}

class SendFeeViewModel: ObservableObject {
    weak var delegate: SendFeeViewModelDelegate?

    @Published private(set) var selectedFeeOption: FeeOption
    @Published private(set) var feeRowViewModels: [FeeRowViewModel] = []

    private let feeOptions: [FeeOption]
    private let blockchain: Blockchain
    private let tokenItem: TokenItem
    private var feeValues: [FeeOption: LoadingValue<String>] = [:]
    private var bag: Set<AnyCancellable> = []

    private var feeFormatter: SwappingFeeFormatter {
        CommonSwappingFeeFormatter(
            balanceFormatter: BalanceFormatter(),
            balanceConverter: BalanceConverter(),
            fiatRatesProvider: SwappingRatesProvider()
        )
    }

    init(input: SendFeeViewModelInput) {
        feeOptions = input.feeOptions
        selectedFeeOption = input.selectedFeeOption
        blockchain = input.blockchain
        tokenItem = input.tokenItem
        feeRowViewModels = makeFeeRowViewModels()

        bind(from: input)
    }

    private func bind(from input: SendFeeViewModelInput) {
        input.feeValues
            .sink { [weak self] feeValues in
                guard let self else { return }
                self.feeValues = formatFees(feeValues)
                feeRowViewModels = makeFeeRowViewModels()
            }
            .store(in: &bag)
    }

    private func formatFees(_ fees: [FeeOption: LoadingValue<Fee>]) -> [FeeOption: LoadingValue<String>] {
        return fees.mapValues { fee in
            switch fee {
            case .loading:
                return .loading
            case .loaded(let value):

                let formattedValue = self.feeFormatter.format(
                    fee: value.amount.value,
                    tokenItem: tokenItem
                )
                return .loaded(formattedValue)
            case .failedToLoad(let error):
                return .failedToLoad(error: error)
            }
        }
    }

    private func makeFeeRowViewModels() -> [FeeRowViewModel] {
        return feeOptions.map { option in
            let value = feeValues[option] ?? .loading
            return makeFeeRowViewModel(option: option, value: value)
        }
    }

    private func makeFeeRowViewModel(option: FeeOption, value: LoadingValue<String>) -> FeeRowViewModel {
        FeeRowViewModel(
            option: option,
            subtitle: value,
            isSelected: .init(root: self, default: false, get: { root in
                root.selectedFeeOption == option
            }, set: { root, newValue in
                if newValue {
                    root.selectedFeeOption = option
                    root.delegate?.didSelectFeeOption(option)
                }
            })
        )
    }
}
