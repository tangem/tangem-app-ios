//
//  TokenFeeProvidersManagerMock.swift
//  TangemTests
//
//  Created for Approve flow unit tests.
//

import Combine
import BlockchainSdk
import TangemExpress
@testable import Tangem

final class TokenFeeProvidersManagerMock: TokenFeeProvidersManager {
    // MARK: - Subjects

    private let _selectedFeeProvider: CurrentValueSubject<any TokenFeeProvider, Never>

    // MARK: - Call tracking

    private(set) var updateInputCalls: [TokenFeeProviderInputData] = []
    private(set) var updateFeesCalls: Int = 0
    private(set) var updateSelectedFeeProviderCalls: [TokenItem] = []

    // MARK: - Init

    init(feeProvider: any TokenFeeProvider) {
        _selectedFeeProvider = .init(feeProvider)
    }

    // MARK: - TokenFeeProvidersManager

    var selectedFeeProvider: any TokenFeeProvider { _selectedFeeProvider.value }

    var selectedFeeProviderPublisher: AnyPublisher<any TokenFeeProvider, Never> {
        _selectedFeeProvider.eraseToAnyPublisher()
    }

    var tokenFeeProviders: [any TokenFeeProvider] { [_selectedFeeProvider.value] }
    var supportFeeSelection: Bool { false }
    var supportFeeSelectionPublisher: AnyPublisher<Bool, Never> { Just(false).eraseToAnyPublisher() }

    func update(feeOption: FeeOption) {}

    func update(input: TokenFeeProviderInputData) {
        updateInputCalls.append(input)
    }

    @discardableResult
    func updateFees() -> Task<Void, Never> {
        updateFeesCalls += 1
        return Task {}
    }

    func updateSelectedFeeProvider(feeTokenItem: TokenItem) {
        updateSelectedFeeProviderCalls.append(feeTokenItem)
    }

    // MARK: - ExpressFeeProvider

    func feeCurrency() -> ExpressWalletCurrency {
        fatalError("Not used in tests")
    }

    func feeCurrencyBalance() throws -> Decimal {
        fatalError("Not used in tests")
    }

    func estimatedFee(amount: Decimal) async throws -> Fee {
        fatalError("Not used in tests")
    }

    func estimatedFee(estimatedGasLimit: Int, otherNativeFee: Decimal?) async throws -> Fee {
        fatalError("Not used in tests")
    }

    func transactionFee(txData: Data, toContractAddress: String) async throws -> Fee {
        fatalError("Not used in tests")
    }

    func transactionFee(data: ExpressTransactionDataType) async throws -> Fee {
        fatalError("Not used in tests")
    }
}
