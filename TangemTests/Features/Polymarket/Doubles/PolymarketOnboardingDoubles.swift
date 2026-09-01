//
//  PolymarketOnboardingDoubles.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemFoundation
import TangemPolymarket
@testable import Tangem

// MARK: - Wallet service

final class PolymarketDepositWalletServiceStub: PolymarketDepositWalletService {
    private(set) var requestedKeys: [(ownerAddress: String?, walletId: String)] = []
    private(set) var deployCalls = 0
    private(set) var approvalsCalls = 0

    private var stateResults: [Result<PolymarketDepositWalletState, PolymarketWalletError>]
    private let deployResult: Result<PolymarketDepositWalletStatus, PolymarketWalletError>
    private let approvalsResult: Result<PolymarketDepositWalletStatus, PolymarketWalletError>

    init(
        stateResults: [Result<PolymarketDepositWalletState, PolymarketWalletError>] = [],
        deployResult: Result<PolymarketDepositWalletStatus, PolymarketWalletError> = .success(.deploymentInProgress),
        approvalsResult: Result<PolymarketDepositWalletStatus, PolymarketWalletError> = .success(.approvalsInProgress)
    ) {
        self.stateResults = stateResults
        self.deployResult = deployResult
        self.approvalsResult = approvalsResult
    }

    convenience init(status: PolymarketDepositWalletStatus, depositWalletAddress: String? = PolymarketDepositWalletServiceStub.depositWalletAddress) {
        self.init(stateResults: [.success(PolymarketDepositWalletState(depositWalletAddress: depositWalletAddress, status: status))])
    }

    convenience init(stateError: PolymarketWalletError) {
        self.init(stateResults: [.failure(stateError)])
    }

    func depositWalletState(
        ownerAddress: String?,
        walletId: String
    ) async throws(PolymarketWalletError) -> PolymarketDepositWalletState {
        requestedKeys.append((ownerAddress: ownerAddress, walletId: walletId))

        let result = stateResults.count > 1 ? stateResults.removeFirst() : stateResults.first

        guard let result else {
            throw PolymarketWalletError.other(.connection(underlying: StubError()))
        }

        switch result {
        case .success(let state): return state
        case .failure(let error): throw error
        }
    }

    func deployWallet(
        ownerAddress: String,
        depositWalletAddress: String,
        walletId: String
    ) async throws(PolymarketWalletError) -> PolymarketDepositWalletStatus {
        deployCalls += 1

        switch deployResult {
        case .success(let status): return status
        case .failure(let error): throw error
        }
    }

    func submitApprovals(_ batch: PolymarketApprovalsBatch) async throws(PolymarketWalletError) -> PolymarketDepositWalletStatus {
        approvalsCalls += 1

        switch approvalsResult {
        case .success(let status): return status
        case .failure(let error): throw error
        }
    }
}

extension PolymarketDepositWalletServiceStub {
    static let depositWalletAddress = "0xdef0000000000000000000000000000000000002"

    struct StubError: Error {}
}

// MARK: - Credentials

final class PolymarketCredentialsRepositoryStub: PolymarketCredentialsRepository {
    private(set) var deletedWalletIds: [UserWalletId] = []
    private(set) var savedCredentials: [PolymarketL2Credentials] = []

    private var stored: PolymarketL2Credentials?
    private let saveError: Error?

    init(stored: PolymarketL2Credentials? = nil, saveError: Error? = nil) {
        self.stored = stored
        self.saveError = saveError
    }

    func save(credentials: PolymarketL2Credentials, userWalletId: UserWalletId) throws {
        if let saveError {
            throw saveError
        }

        savedCredentials.append(credentials)
        stored = credentials
    }

    func load(userWalletId: UserWalletId) -> PolymarketL2Credentials? {
        stored
    }

    func delete(userWalletId: UserWalletId) {
        deletedWalletIds.append(userWalletId)
        stored = nil
    }

    func clean(genericPasswordAccounts: [String]) {}
}

extension PolymarketCredentialsRepositoryStub {
    static let credentials = PolymarketL2Credentials(apiKey: "key", secret: "c2VjcmV0", passphrase: "phrase")
}

// MARK: - Owner address

final class PolymarketOwnerAddressProviderStub: PolymarketOwnerAddressProviding {
    static let ownerAddress = "0xabc0000000000000000000000000000000000001"

    private let derived: String?

    init(derived: String? = nil) {
        self.derived = derived
    }

    func getOwnerAddress() -> String? {
        derived
    }

    func deriveOwnerAddress() async throws(PolymarketDerivationError) -> String {
        guard let derived else {
            throw PolymarketDerivationError.missingWallet
        }

        return derived
    }
}

// MARK: - CLOB

final class PolymarketCLOBServiceStub: PolymarketCLOBService {
    private(set) var balanceCalls = 0

    private let balanceResult: Result<Decimal, Error>

    init(balanceResult: Result<Decimal, Error> = .success(0)) {
        self.balanceResult = balanceResult
    }

    func createCredentials(authHeaders: PolymarketCLOBAuthHeaders) async throws -> PolymarketL2Credentials {
        PolymarketCredentialsRepositoryStub.credentials
    }

    func deriveCredentials(authHeaders: PolymarketCLOBAuthHeaders) async throws -> PolymarketL2Credentials {
        PolymarketCredentialsRepositoryStub.credentials
    }

    func updateBalanceAllowance(credentials: PolymarketL2Credentials, ownerAddress: String) async throws {}

    func balanceAllowance(
        credentials: PolymarketL2Credentials,
        ownerAddress: String
    ) async throws -> PolymarketBalanceAllowance {
        balanceCalls += 1

        switch balanceResult {
        case .success(let balance): return PolymarketBalanceAllowance(balance: balance, allowance: 0)
        case .failure(let error): throw error
        }
    }
}

// MARK: - Balance

final class PolymarketBalanceServiceSpy: PolymarketBalanceService {
    private(set) var updates: [LoadingResult<Decimal, Error>] = []
    private(set) var unavailableCalls = 0

    private let balanceSubject = CurrentValueSubject<PolymarketBalanceState?, Never>(nil)

    var fiatTotalTokenBalanceProvider: TokenBalanceProvider { TokenBalanceProviderTestsMock(balance: 0) }

    var balanceStatePublisher: AnyPublisher<PolymarketBalanceState?, Never> {
        balanceSubject.eraseToAnyPublisher()
    }

    func update(with result: LoadingResult<Decimal, Error>) {
        updates.append(result)
    }

    func markUnavailable() {
        unavailableCalls += 1
    }
}

// MARK: - Account presence

final class PolymarketAccountPresenceStoreStub: PolymarketAccountPresenceStore {
    private var known: Bool

    init(known: Bool = false) {
        self.known = known
    }

    func hasAccount(userWalletId: UserWalletId) -> Bool {
        known
    }

    func setHasAccount(_ value: Bool, for userWalletId: UserWalletId) {
        known = value
    }
}
