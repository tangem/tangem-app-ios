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
    private let credentialsRepository: PolymarketCredentialsRepository
    private let ownerAddressProvider: PolymarketOwnerAddressProviding
    private let balanceService: PolymarketBalanceService
    private let presenceStore: PolymarketAccountPresenceStore

    private let stateSubject = CurrentValueSubject<PolymarketAccountState?, Never>(nil)

    init(
        userWalletId: UserWalletId,
        walletService: PolymarketDepositWalletService,
        clobService: PolymarketCLOBService,
        credentialsRepository: PolymarketCredentialsRepository,
        ownerAddressProvider: PolymarketOwnerAddressProviding,
        balanceService: PolymarketBalanceService,
        presenceStore: PolymarketAccountPresenceStore
    ) {
        id = PolymarketAccountId(userWalletId: userWalletId)
        self.userWalletId = userWalletId
        self.walletService = walletService
        self.clobService = clobService
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

    var fiatTotalTokenBalanceProvider: TokenBalanceProvider {
        balanceService.fiatTotalTokenBalanceProvider
    }

    var balanceStatePublisher: AnyPublisher<PolymarketBalanceState?, Never> {
        balanceService.balanceStatePublisher
    }

    func refreshState() async {
        guard let ownerAddress = ownerAddressProvider.getOwnerAddress() else {
            return
        }

        await resolveState(ownerAddress: ownerAddress)
    }

    func lookupByWalletId() async {
        await resolveState(ownerAddress: ownerAddressProvider.getOwnerAddress())
    }
}

// MARK: - Private implementation

private extension CommonPolymarketAccountModel {
    func resolveState(ownerAddress: String?) async {
        guard presenceStore.hasAccount(userWalletId: userWalletId) else {
            await loadAccountState(ownerAddress: ownerAddress)
            return
        }

        stateSubject.send(makeReadyToTradeState(ownerAddress: ownerAddress))
        await loadBalanceIfPossible(ownerAddress: ownerAddress)
    }

    func loadAccountState(ownerAddress: String?) async {
        if stateSubject.value == nil {
            stateSubject.send(.loading)
        }

        do {
            let walletState = try await walletService.depositWalletState(
                ownerAddress: ownerAddress,
                walletId: userWalletId.stringValue
            )

            if walletState.status == .readyToTrade {
                presenceStore.setHasAccount(true, for: userWalletId)
            }

            let state = makeState(from: walletState, ownerAddress: ownerAddress)
            stateSubject.send(state)

            await loadBalanceIfPossible(ownerAddress: ownerAddress)
        } catch PolymarketWalletError.cancelled {
            if case .loading = stateSubject.value {
                stateSubject.send(nil)
            }
        } catch {
            PolymarketLogger.error("Failed to refresh the account state", error: error)
            balanceService.markUnavailable()
            stateSubject.send(.unavailable)
        }
    }

    func loadBalanceIfPossible(ownerAddress: String?) async {
        guard let ownerAddress, stateSubject.value?.isActive == true else {
            balanceService.markUnavailable()
            return
        }

        await loadBalance(ownerAddress: ownerAddress)
    }

    func makeState(from walletState: PolymarketDepositWalletState, ownerAddress: String?) -> PolymarketAccountState? {
        switch walletState.status {
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

    func loadBalance(ownerAddress: String) async {
        guard let credentials = credentialsRepository.load(userWalletId: userWalletId) else {
            balanceService.markUnavailable()
            return
        }

        balanceService.update(with: .loading)

        do {
            let balanceAllowance = try await clobService.balanceAllowance(
                credentials: credentials,
                ownerAddress: ownerAddress
            )

            balanceService.update(with: .success(balanceAllowance.balance))
        } catch is CancellationError {
            return
        } catch {
            PolymarketLogger.error("Failed to load the collateral balance", error: error)
            balanceService.update(with: .failure(error))
            dropCredentialsIfRejected(error)
        }
    }

    func dropCredentialsIfRejected(_ error: Error) {
        guard case .http(let statusCode, _) = error as? PolymarketAPIError, statusCode == Constants.unauthorizedStatusCode else {
            return
        }

        PolymarketLogger.info("The exchange rejected the credentials, dropping them")
        credentialsRepository.delete(userWalletId: userWalletId)
        balanceService.markUnavailable()
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
