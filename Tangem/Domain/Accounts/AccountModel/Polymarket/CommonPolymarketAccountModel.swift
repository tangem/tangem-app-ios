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
    private let refreshProcessor = SingleTaskProcessor<Void, Never>()

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

    func refreshState() async {
        await refreshProcessor.execute { [weak self] in
            guard let self else { return }

            await loadState()
        }
    }
}

// MARK: - Private implementation

private extension CommonPolymarketAccountModel {
    func loadState() async {
        let ownerAddress = ownerAddressProvider.getOwnerAddress()

        guard !presenceStore.hasAccount(userWalletId: userWalletId) else {
            await publishKnownAccount(ownerAddress: ownerAddress)
            return
        }

        await loadAccount(ownerAddress: ownerAddress)
    }

    func publishKnownAccount(ownerAddress: String?) async {
        stateSubject.send(makeReadyToTradeState(ownerAddress: ownerAddress))

        await loadBalanceIfPossible(ownerAddress: ownerAddress)
    }

    func loadAccount(ownerAddress: String?) async {
        if stateSubject.value == nil {
            stateSubject.send(.loading)
        }

        do {
            let depositWallet = try await walletService.depositWalletState(
                ownerAddress: ownerAddress,
                walletId: userWalletId.stringValue
            )

            if depositWallet.status == .readyToTrade {
                presenceStore.markAccountExists(for: userWalletId)
            }

            stateSubject.send(makeState(from: depositWallet, ownerAddress: ownerAddress))

            await loadBalanceIfPossible(ownerAddress: ownerAddress)
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

    func loadBalanceIfPossible(ownerAddress: String?) async {
        guard let ownerAddress, stateSubject.value?.isActive == true else {
            balanceService.update(.unavailable)
            return
        }

        await loadBalance(ownerAddress: ownerAddress)
    }

    func makeState(from depositWallet: PolymarketDepositWalletState, ownerAddress: String?) -> PolymarketAccountState? {
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

    func loadBalance(ownerAddress: String) async {
        guard let credentials = credentialsRepository.load(userWalletId: userWalletId) else {
            balanceService.update(.unavailable)
            return
        }

        let previous = balanceService.state
        balanceService.update(.loading)

        do {
            let balanceAllowance = try await clobService.balanceAllowance(
                credentials: credentials,
                ownerAddress: ownerAddress
            )

            balanceService.update(.loaded(balanceAllowance.balance))
        } catch is CancellationError {
            balanceService.update(previous ?? .unavailable)
        } catch {
            PolymarketLogger.error("Failed to load the collateral balance", error: error)
            balanceService.update(.failed(error))
            dropCredentialsIfRejected(error)
        }
    }

    func dropCredentialsIfRejected(_ error: Error) {
        guard case .http(let statusCode, _) = error as? PolymarketAPIError, statusCode == Constants.unauthorizedStatusCode else {
            return
        }

        PolymarketLogger.info("The exchange rejected the credentials, dropping them")
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
