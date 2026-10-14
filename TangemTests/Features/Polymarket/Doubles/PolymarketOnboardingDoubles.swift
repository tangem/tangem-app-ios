//
//  PolymarketOnboardingDoubles.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import BlockchainSdk
import TangemFoundation
import TangemPolymarket
import TangemSdk
@testable import Tangem

// MARK: - Wallet service

final class PolymarketDepositWalletServiceStub: PolymarketDepositWalletService {
    private(set) var requestedOwnerAddresses: [String?] = []
    private(set) var deployCalls = 0
    private(set) var submittedBatches: [PolymarketRelayedBatch] = []

    private var stateResults: [Result<PolymarketDepositWallet, PolymarketWalletError>]
    private var deployResults: [Result<PolymarketDepositWalletStatus, PolymarketWalletError>]
    private let approvalsResult: Result<PolymarketDepositWalletStatus, PolymarketWalletError>

    init(
        stateResults: [Result<PolymarketDepositWallet, PolymarketWalletError>] = [],
        deployResults: [Result<PolymarketDepositWalletStatus, PolymarketWalletError>] = [.success(.deploymentInProgress)],
        approvalsResult: Result<PolymarketDepositWalletStatus, PolymarketWalletError> = .success(.approvalsInProgress)
    ) {
        self.stateResults = stateResults
        self.deployResults = deployResults
        self.approvalsResult = approvalsResult
    }

    convenience init(
        status: PolymarketDepositWalletStatus,
        depositWalletAddress: String? = PolymarketDepositWalletServiceStub.depositWalletAddress
    ) {
        self.init(stateResults: [.success(PolymarketDepositWallet(address: depositWalletAddress, status: status))])
    }

    convenience init(stateError: PolymarketWalletError) {
        self.init(stateResults: [.failure(stateError)])
    }

    func depositWalletState(ownerAddress: String?) async throws(PolymarketWalletError) -> PolymarketDepositWallet {
        requestedOwnerAddresses.append(ownerAddress)

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
        depositWalletAddress: String
    ) async throws(PolymarketWalletError) -> PolymarketDepositWalletStatus {
        deployCalls += 1

        let result = deployResults.count > 1 ? deployResults.removeFirst() : deployResults.first

        switch result {
        case .success(let status): return status
        case .failure(let error): throw error
        case .none: return .deploymentInProgress
        }
    }

    func submitApprovals(_ batch: PolymarketRelayedBatch) async throws(PolymarketWalletError) -> PolymarketDepositWalletStatus {
        submittedBatches.append(batch)

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
    private let isStored: Bool

    init(derived: String? = nil, isStored: Bool = true) {
        self.derived = derived
        self.isStored = isStored
    }

    func getOwnerAddress() -> String? {
        isStored ? derived : nil
    }
}

// MARK: - Owner key session

final class PolymarketOwnerKeySessionSpy: PolymarketOwnerKeySession {
    private(set) var prompts = 0

    let signer: PolymarketOnboardingSignerSpy

    private let error: PolymarketOnboardingError?

    init(signer: PolymarketOnboardingSignerSpy = PolymarketOnboardingSignerSpy(), error: PolymarketOnboardingError? = nil) {
        self.signer = signer
        self.error = error
    }

    func derive<Output>(
        andRun work: @escaping (PolymarketOwnerKeySessionContext) async throws -> Output
    ) async throws -> Output {
        prompts += 1

        if let error {
            throw error
        }

        return try await work(
            PolymarketOwnerKeySessionContext(ownerAddress: PolymarketOwnerAddressProviderStub.ownerAddress, signer: signer)
        )
    }
}

// MARK: - CLOB

final class PolymarketCLOBServiceStub: PolymarketCLOBService {
    struct StubError: Error {}

    func order(
        id: String,
        credentials: PolymarketL2Credentials,
        ownerAddress: String
    ) async throws -> PolymarketOrderRecord {
        fatalError("Not reachable from this test")
    }

    private(set) var balanceCalls = 0

    var queuedPriceResults: [Result<Decimal, Error>] = []

    private let balanceResult: Result<Decimal, Error>
    private let deriveResult: Result<PolymarketL2Credentials, Error>
    private let createResult: Result<PolymarketL2Credentials, Error>

    init(
        balanceResult: Result<Decimal, Error> = .success(0),
        deriveResult: Result<PolymarketL2Credentials, Error> = .success(PolymarketCredentialsRepositoryStub.credentials),
        createResult: Result<PolymarketL2Credentials, Error> = .success(PolymarketCredentialsRepositoryStub.credentials)
    ) {
        self.balanceResult = balanceResult
        self.deriveResult = deriveResult
        self.createResult = createResult
    }

    func price(tokenId: String, side: PolymarketOrderSide) async throws -> Decimal {
        guard !queuedPriceResults.isEmpty else { return 0 }

        return try queuedPriceResults.removeFirst().get()
    }

    func createCredentials(authHeaders: PolymarketCLOBAuthHeaders) async throws -> PolymarketL2Credentials {
        try createResult.get()
    }

    func deriveCredentials(authHeaders: PolymarketCLOBAuthHeaders) async throws -> PolymarketL2Credentials {
        try deriveResult.get()
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

    func placeOrder(
        _ signedOrder: PolymarketSignedOrder,
        credentials: PolymarketL2Credentials,
        ownerAddress: String
    ) async throws -> PolymarketOrderPlacement {
        throw StubError()
    }
}

// MARK: - Relayer

final class PolymarketRelayerServiceStub: PolymarketRelayerService {
    static let nonce = "7"

    private let result: Result<String, Error>

    init(result: Result<String, Error> = .success(PolymarketRelayerServiceStub.nonce)) {
        self.result = result
    }

    func walletNonce(ownerAddress: String) async throws -> String {
        try result.get()
    }
}

// MARK: - Onboarding signing

final class PolymarketOnboardingSignerSpy: PolymarketOnboardingSigning {
    static let batchSignature = "0xbatch"

    private(set) var signCalls = 0

    private let error: PolymarketSigningError?

    init(error: PolymarketSigningError? = nil) {
        self.error = error
    }

    func sign(
        approvals: PolymarketRelayedBatch.Unsigned
    ) async throws(PolymarketSigningError) -> PolymarketOnboardingSignatures {
        signCalls += 1

        if let error {
            throw error
        }

        let ownerAddress = PolymarketOwnerAddressProviderStub.ownerAddress

        return PolymarketOnboardingSignatures(
            authHeaders: PolymarketCLOBAuthHeaders(
                ownerAddress: ownerAddress,
                signature: "0xsignature",
                timestamp: "1786128353",
                nonce: PolymarketClobAuth.nonce
            ),
            approvals: approvals.signed(by: ownerAddress, signature: Self.batchSignature)
        )
    }
}

// MARK: - Positions value

final class PolymarketPositionsValueServiceStub: PolymarketPositionsValueService {
    struct StubError: Error {}

    private(set) var calls = 0

    var result: Result<Decimal, Error>

    init(result: Result<Decimal, Error> = .success(0)) {
        self.result = result
    }

    func positionsValue(depositWalletAddress: String) async throws -> Decimal {
        calls += 1

        return try result.get()
    }
}

// MARK: - Balance

final class PolymarketBalanceServiceSpy: PolymarketBalanceService {
    private(set) var updates: [PolymarketBalanceState] = []

    private let balanceSubject = CurrentValueSubject<PolymarketBalanceState?, Never>(nil)

    private lazy var balanceProvider: TokenBalanceProvider = PolymarketBalanceStateBalanceProvider(subject: balanceSubject)

    var unavailableCalls: Int {
        updates.filter { $0.isUnavailable }.count
    }

    var fiatAvailableBalanceProvider: TokenBalanceProvider { balanceProvider }
    var fiatTotalTokenBalanceProvider: TokenBalanceProvider { balanceProvider }
    var collateralTokenBalanceProvider: TokenBalanceProvider { balanceProvider }
    var collateralTotalBalanceProvider: TokenBalanceProvider { balanceProvider }

    var state: PolymarketBalanceState? { updates.last }

    func update(_ state: PolymarketBalanceState) {
        updates.append(state)
        balanceSubject.send(state)
    }
}

private struct PolymarketBalanceStateBalanceProvider: TokenBalanceProvider {
    let subject: CurrentValueSubject<PolymarketBalanceState?, Never>

    var balanceType: TokenBalanceType {
        Self.balanceType(from: subject.value)
    }

    var balanceTypePublisher: AnyPublisher<TokenBalanceType, Never> {
        subject.map(Self.balanceType(from:)).eraseToAnyPublisher()
    }

    var formattedBalanceType: FormattedTokenBalanceType {
        .loaded("")
    }

    var formattedBalanceTypePublisher: AnyPublisher<FormattedTokenBalanceType, Never> {
        Just(formattedBalanceType).eraseToAnyPublisher()
    }

    private static func balanceType(from state: PolymarketBalanceState?) -> TokenBalanceType {
        switch state {
        case .loaded(let balance): .loaded(balance.available)
        case .loading: .loading(.none)
        case .failed: .failure(.none)
        case .unavailable, .none: .empty(.noData)
        }
    }
}

// MARK: - Account model

final class PolymarketAccountModelStub: PolymarketAccountModel {
    let id: PolymarketAccountId
    var state: PolymarketAccountState?
    let collateralTokenBalanceProvider: TokenBalanceProvider
    let collateralTotalBalanceProvider: TokenBalanceProvider
    let fiatAvailableBalanceProvider: TokenBalanceProvider
    let fiatTotalTokenBalanceProvider: TokenBalanceProvider

    init(
        userWalletId: UserWalletId = UserWalletId(value: Data([0x01, 0x02, 0x03])),
        state: PolymarketAccountState?,
        collateralTokenBalanceProvider: TokenBalanceProvider = TokenBalanceProviderTestsMock(balance: 0),
        collateralTotalBalanceProvider: TokenBalanceProvider = TokenBalanceProviderTestsMock(balance: 0),
        fiatAvailableBalanceProvider: TokenBalanceProvider = TokenBalanceProviderTestsMock(balance: 0),
        fiatTotalTokenBalanceProvider: TokenBalanceProvider = TokenBalanceProviderTestsMock(balance: 0)
    ) {
        id = PolymarketAccountId(userWalletId: userWalletId)
        self.state = state
        self.collateralTokenBalanceProvider = collateralTokenBalanceProvider
        self.collateralTotalBalanceProvider = collateralTotalBalanceProvider
        self.fiatAvailableBalanceProvider = fiatAvailableBalanceProvider
        self.fiatTotalTokenBalanceProvider = fiatTotalTokenBalanceProvider
    }

    var statePublisher: AnyPublisher<PolymarketAccountState?, Never> { .just(output: state) }

    func refreshState(scope: PolymarketBalanceRefreshScope) async {}

    func refreshBalance(scope: PolymarketBalanceRefreshScope) async {}
}

// MARK: - Account presence

final class PolymarketAccountPresenceStoreStub: PolymarketAccountPresenceStore {
    private var known: Bool
    private var positions: Bool
    private var shownCount: Int?

    init(known: Bool = false, positions: Bool = false) {
        self.known = known
        self.positions = positions
    }

    func hasAccount(userWalletId: UserWalletId) -> Bool {
        known
    }

    func markAccountExists(for userWalletId: UserWalletId) {
        known = true
    }

    func hadPositions(userWalletId: UserWalletId) -> Bool {
        positions
    }

    func markPositionsExisted(for userWalletId: UserWalletId) {
        positions = true
    }

    func shownPositionsCount(userWalletId: UserWalletId) -> Int? {
        shownCount
    }

    func setShownPositionsCount(_ count: Int, for userWalletId: UserWalletId) {
        shownCount = count
    }

    func delete(userWalletId: UserWalletId) {
        known = false
        positions = false
        shownCount = nil
    }
}

// MARK: - Card signing

final class PolymarketCardSignerStub: TangemSigner {
    private(set) var signCalls = 0
    private(set) var requestedHashes: [Data] = []

    let hasNFCInteraction = false
    let latestSignerType: TangemSignerType? = nil

    let publicKey: Data

    private let privateKey: Data
    private var produced: [Data: String] = [:]

    init() throws {
        let keyPair = try Secp256k1Utils().generateKeyPair()

        privateKey = keyPair.privateKey
        publicKey = keyPair.publicKey
    }

    func signature(over hash: Data) -> String? {
        produced[hash]
    }

    func sign(hashes: [Data], walletPublicKey: Wallet.PublicKey) -> AnyPublisher<[SignatureInfo], any Error> {
        signCalls += 1
        requestedHashes.append(contentsOf: hashes)

        do {
            let signatures = try hashes.map { hash in
                let info = SignatureInfo(
                    signature: try Secp256k1Utils().sign(hash, with: privateKey),
                    publicKey: publicKey,
                    hash: hash.getSHA256()
                )
                produced[hash] = try info.unmarshal().hexString.lowercased().addHexPrefix()

                return info
            }

            return Just(signatures).setFailureType(to: Error.self).eraseToAnyPublisher()
        } catch {
            return Fail(error: error).eraseToAnyPublisher()
        }
    }

    func sign(hash: Data, walletPublicKey: Wallet.PublicKey) -> AnyPublisher<SignatureInfo, any Error> {
        sign(hashes: [hash], walletPublicKey: walletPublicKey)
            .compactMap(\.first)
            .eraseToAnyPublisher()
    }

    func sign(dataToSign: [SignData], walletPublicKey: Wallet.PublicKey) -> AnyPublisher<[SignatureInfo], any Error> {
        sign(hashes: dataToSign.flatMap(\.hashes), walletPublicKey: walletPublicKey)
    }
}

// MARK: - Discovery API

final class PolymarketAPIProviderStub: PolymarketAPIProvider {
    private(set) var searchRequests: [PolymarketSearchRequest] = []
    private(set) var quoteRequests: [PolymarketOrderQuoteRequest] = []

    var queuedQuoteResults: [Result<PolymarketOrderQuote, Error>] = []
    var categoryList: [PolymarketCategory] = []
    var queuedCategoryResults: [Result<[PolymarketCategory], Error>] = []
    var slowEventCategories: Set<Int> = []

    static let slowEventsDelay: UInt64 = 200_000_000
    var eventPages: [EventsPageKey: PolymarketEventsPage] = [:]
    var eventErrors: [EventsPageKey: Error] = [:]
    private(set) var eventsRequests: [PolymarketEventsRequest] = []

    private var searchResults: [Result<PolymarketSearchResult, Error>]
    private let quoteResult: PolymarketOrderQuote?

    init(
        searchResults: [Result<PolymarketSearchResult, Error>] = [],
        quoteResult: PolymarketOrderQuote? = nil
    ) {
        self.searchResults = searchResults
        self.quoteResult = quoteResult
    }

    func search(request: PolymarketSearchRequest) async throws -> PolymarketSearchResult {
        searchRequests.append(request)

        guard !searchResults.isEmpty else {
            return PolymarketSearchResult(events: [], page: request.page, total: 0, hasNext: false)
        }

        return try searchResults.removeFirst().get()
    }

    func categories(locale: String?) async throws -> [PolymarketCategory] {
        if !queuedCategoryResults.isEmpty {
            return try queuedCategoryResults.removeFirst().get()
        }

        return categoryList
    }

    func events(request: PolymarketEventsRequest) async throws -> PolymarketEventsPage {
        eventsRequests.append(request)

        if let category = request.category, slowEventCategories.contains(category) {
            try await Task.sleep(nanoseconds: Self.slowEventsDelay)
        }

        let key = EventsPageKey(category: request.category, cursor: request.cursor)

        if let error = eventErrors[key] {
            throw error
        }

        return eventPages[key] ?? PolymarketEventsPage(events: [], cursor: nil, hasNext: false)
    }

    struct EventsPageKey: Hashable {
        let category: Int?
        let cursor: String?
    }

    func event(id: String) async throws -> PolymarketEvent {
        throw PolymarketDepositWalletServiceStub.StubError()
    }

    func series() async throws -> [PolymarketSeries] { [] }

    func seriesEvents(seriesId: String) async throws -> PolymarketSeriesEvents {
        throw PolymarketDepositWalletServiceStub.StubError()
    }

    func orderQuote(request: PolymarketOrderQuoteRequest) async throws -> PolymarketOrderQuote {
        quoteRequests.append(request)

        if !queuedQuoteResults.isEmpty {
            return try queuedQuoteResults.removeFirst().get()
        }

        guard let quoteResult else {
            throw PolymarketDepositWalletServiceStub.StubError()
        }

        return quoteResult
    }

    func positions(request: PolymarketPositionsRequest) async throws -> PolymarketPositionsPage {
        throw PolymarketDepositWalletServiceStub.StubError()
    }

    func closedPositions(request: PolymarketClosedPositionsRequest) async throws -> PolymarketClosedPositionsPage {
        throw PolymarketDepositWalletServiceStub.StubError()
    }

    func positionOutcome(request: PolymarketPositionOutcomeRequest) async throws -> PolymarketPosition? {
        throw PolymarketDepositWalletServiceStub.StubError()
    }
}

// MARK: - Geoblock

final class PolymarketGeoblockServiceStub: PolymarketGeoblockService {
    private let result: Result<PolymarketGeoblock, Error>

    init(isBlocked: Bool = false) {
        result = .success(PolymarketGeoblock(isBlocked: isBlocked, country: nil, region: nil))
    }

    init(error: Error) {
        result = .failure(error)
    }

    func geoblock() async throws -> PolymarketGeoblock {
        try result.get()
    }
}

final class PolymarketGeoblockStateProviderStub: PolymarketGeoblockStateProvider {
    let state: PolymarketGeoblockState

    var statePublisher: AnyPublisher<PolymarketGeoblockState, Never> {
        .just(output: state)
    }

    init(state: PolymarketGeoblockState = .allowed) {
        self.state = state
    }

    func refresh() {}
}

// MARK: - Event opening routing

final class PolymarketEventOpeningRoutableSpy: PolymarketEventOpeningRoutable {
    static let ignored = PolymarketEventOpeningRoutableSpy()

    private(set) var openedEventIDs: [String] = []
    private(set) var openedOutcomes: [(market: PolymarketMarket, outcome: PolymarketOutcome, eventTitle: String, isBuy: Bool)] = []
    private(set) var openedEventCategories: [PolymarketCategory?] = []
    private(set) var regionWarningOpenings = 0
    private(set) var lastOnPlaced: (@MainActor (PolymarketOrderIndexing) -> Void)?

    func openRegionWarning() {
        regionWarningOpenings += 1
    }

    func openEventDetails(
        eventID: String,
        category: PolymarketCategory?,
        onOrderPlaced: @escaping @MainActor (PolymarketOrderIndexing) -> Void
    ) {
        openedEventIDs.append(eventID)
        openedEventCategories.append(category)
        lastOnPlaced = onOrderPlaced
    }

    func openOrder(
        market: PolymarketMarket,
        outcome: PolymarketOutcome,
        eventTitle: String,
        request: PolymarketOrderRequest,
        onPlaced: @escaping @MainActor (PolymarketOrderIndexing) -> Void
    ) {
        openedOutcomes.append((market, outcome, eventTitle, request.side == .buy))
        lastOnPlaced = onPlaced
    }
}
