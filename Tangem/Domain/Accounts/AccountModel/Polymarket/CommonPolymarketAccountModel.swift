//
//  CommonPolymarketAccountModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemFoundation
import TangemPolymarket

final class CommonPolymarketAccountModel {
    let id: PolymarketAccountId

    private let userWalletId: UserWalletId
    private let walletService: PolymarketDepositWalletService
    private let clobService: PolymarketCLOBService
    private let positionsValueService: PolymarketPositionsValueService
    private let credentialsRepository: PolymarketCredentialsRepository
    private let ownerAddressProvider: PolymarketOwnerAddressProviding
    private let balanceService: PolymarketBalanceService
    private let presenceStore: PolymarketAccountPresenceStore

    private let stateSubject = CurrentValueSubject<PolymarketAccountState?, Never>(nil)
    private let refreshProcessor = SingleTaskProcessor<Void, Never>()
    private let lastPositionsValue = OSAllocatedUnfairLock<Decimal?>(initialState: nil)
    private let positionsReads = OSAllocatedUnfairLock<Int>(initialState: 0)
    private let stateReads = OSAllocatedUnfairLock<Int>(initialState: 0)

    init(
        userWalletId: UserWalletId,
        walletService: PolymarketDepositWalletService,
        clobService: PolymarketCLOBService,
        positionsValueService: PolymarketPositionsValueService,
        credentialsRepository: PolymarketCredentialsRepository,
        ownerAddressProvider: PolymarketOwnerAddressProviding,
        balanceService: PolymarketBalanceService,
        presenceStore: PolymarketAccountPresenceStore
    ) {
        id = PolymarketAccountId(userWalletId: userWalletId)
        self.userWalletId = userWalletId
        self.walletService = walletService
        self.clobService = clobService
        self.positionsValueService = positionsValueService
        self.credentialsRepository = credentialsRepository
        self.ownerAddressProvider = ownerAddressProvider
        self.balanceService = balanceService
        self.presenceStore = presenceStore
    }
}

// MARK: - PolymarketAccountModel protocol conformance

extension CommonPolymarketAccountModel: PolymarketAccountModel {
    var state: PolymarketAccountState? {
        stateSubject.value
    }

    var statePublisher: AnyPublisher<PolymarketAccountState?, Never> {
        stateSubject.eraseToAnyPublisher()
    }

    var fiatAvailableBalanceProvider: TokenBalanceProvider {
        balanceService.fiatAvailableBalanceProvider
    }

    var fiatTotalTokenBalanceProvider: TokenBalanceProvider {
        balanceService.fiatTotalTokenBalanceProvider
    }

    var collateralTokenBalanceProvider: TokenBalanceProvider {
        balanceService.collateralTokenBalanceProvider
    }

    var collateralTotalBalanceProvider: TokenBalanceProvider {
        balanceService.collateralTotalBalanceProvider
    }

    func refreshState(scope: PolymarketBalanceRefreshScope) async {
        let positionsReadsBefore = positionsReads.withLock { $0 }
        let stateReadsBefore = stateReads.withLock { $0 }

        await runRound(scope: scope)

        let joinedARoundThatSkippedTheState = stateReads.withLock { $0 } == stateReadsBefore
        let joinedARoundThatSkippedThePositions = scope == .full && positionsReads.withLock { $0 } == positionsReadsBefore

        guard joinedARoundThatSkippedTheState || joinedARoundThatSkippedThePositions else {
            return
        }

        await runRound(scope: scope)
    }

    func refreshBalance(scope: PolymarketBalanceRefreshScope) async {
        await refreshProcessor.execute { [weak self] in
            guard let self else { return }

            guard stateSubject.value?.isActive == true else {
                await loadState(scope: scope)
                return
            }

            await loadBalanceIfPossible(ownerAddress: ownerAddressProvider.getOwnerAddress(), scope: scope)
        }
    }
}

// MARK: - Private implementation

private extension CommonPolymarketAccountModel {
    func runRound(scope: PolymarketBalanceRefreshScope) async {
        await refreshProcessor.execute { [weak self] in
            guard let self else { return }

            await loadState(scope: scope)
        }
    }

    func loadState(scope: PolymarketBalanceRefreshScope) async {
        stateReads.withLock { $0 += 1 }

        let ownerAddress = ownerAddressProvider.getOwnerAddress()

        guard !presenceStore.hasAccount(userWalletId: userWalletId) else {
            await publishKnownAccount(ownerAddress: ownerAddress, scope: scope)
            return
        }

        await loadAccount(ownerAddress: ownerAddress, scope: scope)
    }

    func publishKnownAccount(ownerAddress: String?, scope: PolymarketBalanceRefreshScope) async {
        stateSubject.send(makeReadyToTradeState(ownerAddress: ownerAddress))

        await loadBalanceIfPossible(ownerAddress: ownerAddress, scope: scope)
    }

    func loadAccount(ownerAddress: String?, scope: PolymarketBalanceRefreshScope) async {
        if stateSubject.value == nil {
            stateSubject.send(.loading)
        }

        do {
            let depositWallet = try await walletService.depositWalletState(ownerAddress: ownerAddress)

            if depositWallet.status == .readyToTrade {
                presenceStore.markAccountExists(for: userWalletId)
            }

            stateSubject.send(makeState(from: depositWallet, ownerAddress: ownerAddress))

            await loadBalanceIfPossible(ownerAddress: ownerAddress, scope: scope)
        } catch PolymarketWalletError.cancelled {
            if case .loading = stateSubject.value {
                stateSubject.send(nil)
            }
        } catch {
            PolymarketLogger.error("Failed to refresh the account state", error: error)
            balanceService.update(.unavailable)
            stateSubject.send(.unavailable)
        }
    }

    func loadBalanceIfPossible(ownerAddress: String?, scope: PolymarketBalanceRefreshScope) async {
        guard let ownerAddress, stateSubject.value?.isActive == true else {
            balanceService.update(.unavailable)
            return
        }

        await loadBalance(ownerAddress: ownerAddress, scope: scope)
    }

    func makeState(from depositWallet: PolymarketDepositWallet, ownerAddress: String?) -> PolymarketAccountState? {
        switch depositWallet.status {
        case .notCreated:
            nil
        case .deploymentInProgress:
            .onboarding(.deploying)
        case .deployed:
            .onboarding(.deployed)
        case .approvalsInProgress:
            .onboarding(.approving)
        case .deploymentFailed:
            .onboardingFailed(.deploying)
        case .approvalsFailed:
            .onboardingFailed(.approving)
        case .readyToTrade:
            makeReadyToTradeState(ownerAddress: ownerAddress)
        case .unknown:
            makeUnrecognizedStatusState()
        }
    }

    func makeReadyToTradeState(ownerAddress: String?) -> PolymarketAccountState {
        guard ownerAddress != nil, credentialsRepository.load(userWalletId: userWalletId) != nil else {
            return .syncNeeded
        }

        return .active
    }

    func loadBalance(ownerAddress: String, scope: PolymarketBalanceRefreshScope) async {
        guard let credentials = credentialsRepository.load(userWalletId: userWalletId) else {
            balanceService.update(.unavailable)
            return
        }

        let previous = balanceService.state
        balanceService.update(.loading)

        async let positionsValue = loadPositionsValue(ownerAddress: ownerAddress, scope: scope)

        do {
            let balanceAllowance = try await clobService.balanceAllowance(
                credentials: credentials,
                ownerAddress: ownerAddress
            )

            let balance = PolymarketBalance(
                available: balanceAllowance.balance,
                positionsValue: await positionsValue
            )

            balanceService.update(.loaded(balance))
        } catch is CancellationError {
            balanceService.update(previous ?? .unavailable)
        } catch {
            PolymarketLogger.error("Failed to load the collateral balance", error: error)
            balanceService.update(.failed(error))
            dropCredentialsIfRejected(error)
        }
    }

    func loadPositionsValue(ownerAddress: String, scope: PolymarketBalanceRefreshScope) async -> PolymarketBalance.PositionsValue {
        guard scope == .full else {
            let known = lastPositionsValue.withLock { $0 }

            return known.map { .reused($0) } ?? .unknown
        }

        positionsReads.withLock { $0 += 1 }

        do {
            let depositWalletAddress = try PolymarketDepositWalletDeriver.derive(ownerAddress: ownerAddress)
            let value = try await positionsValueService.positionsValue(depositWalletAddress: depositWalletAddress)

            lastPositionsValue.withLock { $0 = value }

            return .loaded(value)
        } catch is CancellationError {
            return .unknown
        } catch {
            PolymarketLogger.error("Failed to load the positions value", error: error)
            lastPositionsValue.withLock { $0 = nil }

            return .unknown
        }
    }

    func dropCredentialsIfRejected(_ error: Error) {
        guard case .http(let statusCode, _) = error as? PolymarketAPIError, statusCode == Constants.unauthorizedStatusCode else {
            return
        }

        credentialsRepository.delete(userWalletId: userWalletId)
        balanceService.update(.unavailable)
        stateSubject.send(.syncNeeded)
    }

    func makeUnrecognizedStatusState() -> PolymarketAccountState? {
        PolymarketLogger.warning("Unrecognized wallet status returned by the backend")

        guard let current = stateSubject.value, !current.isLoading else {
            return nil
        }

        return current
    }
}

// MARK: - Constants

private extension CommonPolymarketAccountModel {
    enum Constants {
        static let unauthorizedStatusCode = 401
    }
}
