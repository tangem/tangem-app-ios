//
//  ControllableTokenFeeProviderStub.swift
//  TangemTests
//
//  Test stub for TokenFeeProvider where state, balance and selected fee can be
//  mutated externally to drive CommonTokenFeeProvidersManager's switching logic.
//

import Combine
import BlockchainSdk
@testable import Tangem

final class ControllableTokenFeeProviderStub: TokenFeeProvider {
    let feeTokenItem: TokenItem
    let hasMultipleFeeOptions: Bool = false

    private let _state: CurrentValueSubject<TokenFeeProviderState, Never>
    private let _balance: CurrentValueSubject<TokenBalanceType, Never>
    private let _selectedTokenFee: CurrentValueSubject<TokenFee, Never>

    private(set) var setupCalls: [TokenFeeProviderInputData] = []
    private(set) var updateFeesCallCount: Int = 0

    init(
        feeTokenItem: TokenItem,
        state: TokenFeeProviderState = .idle,
        balance: TokenBalanceType = .loaded(0),
        selectedTokenFee: TokenFee
    ) {
        self.feeTokenItem = feeTokenItem
        _state = .init(state)
        _balance = .init(balance)
        _selectedTokenFee = .init(selectedTokenFee)
    }

    // MARK: - Test mutators

    func set(state: TokenFeeProviderState) { _state.send(state) }
    func set(balance: TokenBalanceType) { _balance.send(balance) }
    func set(selectedTokenFee fee: TokenFee) { _selectedTokenFee.send(fee) }

    // MARK: - TokenFeeProvider

    var balanceFeeTokenState: TokenBalanceType { _balance.value }
    var balanceTypePublisher: AnyPublisher<TokenBalanceType, Never> { _balance.eraseToAnyPublisher() }
    var formattedFeeTokenBalance: FormattedTokenBalanceType { .loaded("\(_balance.value.value ?? 0)") }

    var state: TokenFeeProviderState { _state.value }
    var statePublisher: AnyPublisher<TokenFeeProviderState, Never> { _state.eraseToAnyPublisher() }

    var selectedTokenFee: TokenFee { _selectedTokenFee.value }
    var selectedTokenFeePublisher: AnyPublisher<TokenFee, Never> { _selectedTokenFee.eraseToAnyPublisher() }

    var fees: [TokenFee] { [_selectedTokenFee.value] }
    var feesPublisher: AnyPublisher<[TokenFee], Never> { _selectedTokenFee.map { [$0] }.eraseToAnyPublisher() }

    func select(feeOption: FeeOption) {}
    func setup(input: TokenFeeProviderInputData) { setupCalls.append(input) }

    @discardableResult
    func updateFees() -> Task<Void, Never> {
        updateFeesCallCount += 1
        return Task {}
    }

    func estimateFee(input: TokenFeeProviderInputData) async throws -> [BSDKFee] {
        _selectedTokenFee.value.value.value.map { [$0] } ?? []
    }
}
