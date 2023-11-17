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

protocol SendFeeViewModelInput {
    var selectedFeeOption: FeeOption { get }
    var feeOptions: [FeeOption] { get }
    var feeValues: AnyPublisher<[FeeOption: LoadingValue<String>], Never> { get }
}

protocol SendFeeViewModelDelegate: AnyObject {
    func didSelectFeeOption(_ feeOption: FeeOption)
}

class SendFeeViewModel: ObservableObject {
    weak var delegate: SendFeeViewModelDelegate?

    @Published private(set) var selectedFeeOption: FeeOption
    @Published private(set) var feeRowViewModels: [FeeRowViewModel] = []

    private let feeOptions: [FeeOption]
    private var feeValues: [FeeOption: LoadingValue<String>] = [:]
    private var bag: Set<AnyCancellable> = []

    init(input: SendFeeViewModelInput) {
        feeOptions = input.feeOptions
        selectedFeeOption = input.selectedFeeOption
        feeRowViewModels = makeFeeRowViewModels()

        bind(from: input)
    }

    private func bind(from input: SendFeeViewModelInput) {
        input.feeValues
            .sink { [weak self] feeValues in
                guard let self else { return }
                self.feeValues = feeValues
                feeRowViewModels = makeFeeRowViewModels()
            }
            .store(in: &bag)
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
