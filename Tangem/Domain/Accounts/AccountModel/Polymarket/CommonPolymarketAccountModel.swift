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

    private(set) var depositWalletAddress: String?

    private let userWalletId: UserWalletId
    private let walletService: PolymarketWalletService
    private let credentialsRepository: PolymarketCredentialsRepository
    private let ownerAddressProvider: PolymarketOwnerAddressProviding

    private let stateSubject = CurrentValueSubject<PolymarketAccountState?, Never>(nil)

    init(
        userWalletId: UserWalletId,
        walletService: PolymarketWalletService,
        credentialsRepository: PolymarketCredentialsRepository,
        ownerAddressProvider: PolymarketOwnerAddressProviding
    ) {
        id = PolymarketAccountId(userWalletId: userWalletId)
        self.userWalletId = userWalletId
        self.walletService = walletService
        self.credentialsRepository = credentialsRepository
        self.ownerAddressProvider = ownerAddressProvider
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

    func refreshState() async {
        guard let ownerAddress = ownerAddressProvider.getOwnerAddress() else {
            stateSubject.send(nil)
            return
        }

        let previousState = stateSubject.value

        if previousState == nil {
            stateSubject.send(.loading)
        }

        do {
            let walletState = try await walletService.walletState(ownerAddress: ownerAddress)
            depositWalletAddress = walletState.depositWalletAddress
            stateSubject.send(makeState(from: walletState))
        } catch PolymarketWalletError.cancelled {
            stateSubject.send(previousState)
        } catch {
            PolymarketLogger.error("Failed to refresh the account state", error: error)
            stateSubject.send(.unavailable)
        }
    }
}

// MARK: - Private implementation

private extension CommonPolymarketAccountModel {
    func makeState(from walletState: PolymarketWalletState) -> PolymarketAccountState? {
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
            makeReadyToTradeState(depositWalletAddress: walletState.depositWalletAddress)
        case .unknown:
            makeUnrecognizedStatusState()
        }
    }

    func makeReadyToTradeState(depositWalletAddress: String?) -> PolymarketAccountState {
        guard let depositWalletAddress else {
            PolymarketLogger.warning("Ready to trade without a deposit wallet address")
            return .unavailable
        }

        guard credentialsRepository.load(userWalletId: userWalletId) != nil else {
            return .syncNeeded
        }

        return .active(depositWalletAddress: depositWalletAddress)
    }

    /// The BFF contract requires an unrecognized status to read as "not ready, keep polling", never as a
    /// failure, so the last known state stands and only the value is reported.
    func makeUnrecognizedStatusState() -> PolymarketAccountState? {
        PolymarketLogger.warning("Unrecognized wallet status returned by the backend")
        return stateSubject.value
    }
}
