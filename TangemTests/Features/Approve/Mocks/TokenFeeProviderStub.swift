//
//  TokenFeeProviderStub.swift
//  TangemTests
//
//  Created for Approve flow unit tests.
//

import Combine
import BlockchainSdk
@testable import Tangem

final class TokenFeeProviderStub: TokenFeeProvider {
    let feeTokenItem: TokenItem
    let hasMultipleFeeOptions: Bool = false

    private let _state = CurrentValueSubject<TokenFeeProviderState, Never>(.idle)
    private let _selectedTokenFee: CurrentValueSubject<TokenFee, Never>

    init(feeTokenItem: TokenItem, initialFee: TokenFee) {
        self.feeTokenItem = feeTokenItem
        _selectedTokenFee = .init(initialFee)
    }

    var balanceFeeTokenState: TokenBalanceType { .loaded(100) }
    var balanceTypePublisher: AnyPublisher<TokenBalanceType, Never> { Just(.loaded(100)).eraseToAnyPublisher() }
    var formattedFeeTokenBalance: FormattedTokenBalanceType { .loaded("100") }

    var state: TokenFeeProviderState { _state.value }
    var statePublisher: AnyPublisher<TokenFeeProviderState, Never> { _state.eraseToAnyPublisher() }

    var selectedTokenFee: TokenFee { _selectedTokenFee.value }
    var selectedTokenFeePublisher: AnyPublisher<TokenFee, Never> { _selectedTokenFee.eraseToAnyPublisher() }

    var fees: [TokenFee] { [_selectedTokenFee.value] }
    var feesPublisher: AnyPublisher<[TokenFee], Never> { _selectedTokenFee.map { [$0] }.eraseToAnyPublisher() }

    func select(feeOption: FeeOption) {}
    func setup(input: TokenFeeProviderInputData) {}

    @discardableResult
    func updateFees() -> Task<Void, Never> { Task {} }
}
