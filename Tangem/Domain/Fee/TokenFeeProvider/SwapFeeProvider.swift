//
//  SwapFeeProvider.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemFoundation

protocol SwapFeeProviderInput: AnyObject {
    var swapManagerState: SwapManagerState { get }
    var swapManagerStatePublisher: AnyPublisher<SwapManagerState, Never> { get }

    func selectedFeeTokenItem() -> TokenItem?
    func updateFees()
}

final class SwapFeeProvider {
    private weak var input: SwapFeeProviderInput?
    private var supportingFeeOption: [FeeOption] { [.market, .fast] }

    init(input: SwapFeeProviderInput) {
        self.input = input
    }
}

// MARK: - FeeSelectorInteractorInput

extension SwapFeeProvider: FeeSelectorInteractorInput {
    var selectedFee: TokenFee? {
        guard let input else {
            return nil
        }

        return mapToSelectedFee(state: input.swapManagerState)
    }

    var selectedFeePublisher: AnyPublisher<TokenFee?, Never> {
        guard let input else {
            return .just(output: nil)
        }

        return input.swapManagerStatePublisher
            .withWeakCaptureOf(self)
            .map { $0.mapToSelectedFee(state: $1) }
            .eraseToAnyPublisher()
    }
}

// MARK: - SendFeeProvider

extension SwapFeeProvider: SendFeeProvider {
    var fees: [TokenFee] {
        guard let input else {
            return []
        }

        return mapToFees(state: input.swapManagerState)
    }

    var feesPublisher: AnyPublisher<[TokenFee], Never> {
        guard let input else {
            return .just(output: [])
        }

        return input.swapManagerStatePublisher
            .withWeakCaptureOf(self)
            .map { $0.mapToFees(state: $1) }
            .eraseToAnyPublisher()
    }

    func updateFees() {
        input?.updateFees()
    }
}

// swapManager.swappingPair.sender.get().feeTokenItem

// MARK: - Private

private extension SwapFeeProvider {
    func mapToSelectedFee(state: SwapManagerState) -> TokenFee? {
        guard let feeTokenItem = input?.selectedFeeTokenItem() else {
            assertionFailure("FeeTokenItem is not found")
            return nil
        }

        switch state {
        case .idle, .loading:
            return TokenFee(option: .market, tokenItem: feeTokenItem, value: .loading)
        case .restriction(.requiredRefresh(let occurredError), _):
            return TokenFee(option: .market, tokenItem: feeTokenItem, value: .failure(occurredError))
        case let state:
            let fee = try? state.fees.selectedFee()

            return fee.map { fee in
                return TokenFee(option: state.fees.selected, tokenItem: feeTokenItem, value: .success(fee))
            }
        }
    }

    func mapToFees(state: SwapManagerState) -> TokenFeesList {
        guard let feeTokenItem = input?.selectedFeeTokenItem() else {
            assertionFailure("FeeTokenItem is not found")
            return []
        }

        switch state {
        case .idle, .loading:
            return TokenFeeConverter.mapToLoadingSendFees(options: supportingFeeOption, feeTokenItem: feeTokenItem)
        case .restriction(.requiredRefresh(let occurredError), _):
            return TokenFeeConverter.mapToFailureSendFees(options: supportingFeeOption, feeTokenItem: feeTokenItem, error: occurredError)
        case let state:
            let fees = state.fees.fees.map(\.value)

            return TokenFeeConverter
                .mapToSendFees(fees: fees, feeTokenItem: feeTokenItem)
                .filter { supportingFeeOption.contains($0.option) }
        }
    }
}
