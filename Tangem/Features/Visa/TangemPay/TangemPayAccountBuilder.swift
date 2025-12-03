//
//  TangemPayAccountBuilder.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import TangemVisa
import TangemFoundation
import Combine

struct TangemPayAccountBuilder {
    func makeTangemPayAuthorizer(
        authorizerType: AuthorizerType,
        userWalletId: UserWalletId,
        keysRepository: KeysRepository,
        tangemPayAuthorizingInteractor: TangemPayAuthorizing,
        signer: TangemSigner
    ) async throws -> TangemPayAuthorizer {
        let authorizer: TangemPayAuthorizer? = switch authorizerType {
        case .availability:
            try await buildAvailabilityAuthorizer(
                userWalletId: userWalletId,
                keysRepository: keysRepository,
                tangemPayAuthorizingInteractor: tangemPayAuthorizingInteractor,
                signer: signer
            )

        case .paeraCustomer:
            try await buildPaeraCustomerAuthorizer(
                userWalletId: userWalletId,
                keysRepository: keysRepository,
                tangemPayAuthorizingInteractor: tangemPayAuthorizingInteractor,
                signer: signer
            )
        }

        guard let authorizer else {
            throw Error.authorizerNotFound
        }

        return authorizer
    }

    func buildAuthorizationTokenHandler(
        authorizer: TangemPayAuthorizer
    ) -> TangemPayAuthorizationTokensHandler {
        TangemPayAuthorizationTokensHandlerBuilder()
            .buildTangemPayAuthorizationTokensHandler(
                customerWalletId: authorizer.customerWalletId,
                authorizationService: authorizer.authorizationService,
                setSyncNeeded: authorizer.setSyncNeeded,
                setUnavailable: authorizer.setUnavailable
            )
    }

    func makeTangemPayAccount(
        authorizer: TangemPayAuthorizer,
        userWalletId: UserWalletId,
        keysRepository: KeysRepository,
        tangemPayAuthorizingInteractor: TangemPayAuthorizing,
        signer: TangemSigner,
        customerInfoManagementService: CustomerInfoManagementService
    ) async throws -> TangemPayAccount {
        return makeTangemPayAccount(
            authorizer: authorizer,
            signer: signer,
            userWalletId: userWalletId,
            customerInfoManagementService: customerInfoManagementService
        )
    }
}

// MARK: - Private

private extension TangemPayAccountBuilder {
    private func buildAvailabilityAuthorizer(
        userWalletId: UserWalletId,
        keysRepository: KeysRepository,
        tangemPayAuthorizingInteractor: TangemPayAuthorizing,
        signer: TangemSigner
    ) async throws -> TangemPayAuthorizer? {
        let isTangemPayAvailable = try await TangemPayAPIServiceBuilder()
            .buildTangemPayAvailabilityService()
            .loadEligibility()
            .isTangemPayAvailable
        guard isTangemPayAvailable else { return nil }
        let walletId = userWalletId.stringValue

        let authorizer = TangemPayAuthorizer(
            customerWalletId: walletId,
            interactor: tangemPayAuthorizingInteractor,
            keysRepository: keysRepository,
            state: .unavailable
        )

        await MainActor.run {
            AppSettings.shared.tangemPayIsPaeraCustomer[walletId] = true
        }

        return authorizer
    }

    private func buildPaeraCustomerAuthorizer(
        userWalletId: UserWalletId,
        keysRepository: KeysRepository,
        tangemPayAuthorizingInteractor: TangemPayAuthorizing,
        signer: TangemSigner
    ) async throws -> TangemPayAuthorizer? {
        let walletId = userWalletId.stringValue

        let authorizerState: TangemPayAuthorizer.State? = await {
            do {
                await MainActor.run {
                    AppSettings.shared.tangemPayIsPaeraCustomer[walletId] = true
                }

                if let (customerWalletAddress, tokens) = TangemPayUtilities.getCustomerWalletAddressAndAuthorizationTokens(
                    customerWalletId: walletId,
                    keysRepository: keysRepository
                ) {
                    return .authorized(customerWalletAddress: customerWalletAddress, tokens: tokens)
                } else {
                    return .syncNeeded
                }
            } catch {
                if await AppSettings.shared.tangemPayIsPaeraCustomer[walletId, default: false] {
                    return .unavailable
                } else {
                    return nil
                }
            }
        }()

        guard let authorizerState else {
            throw Error.authorizerNotFound
        }

        let authorizer = TangemPayAuthorizer(
            customerWalletId: walletId,
            interactor: tangemPayAuthorizingInteractor,
            keysRepository: keysRepository,
            state: authorizerState
        )

        return authorizer
    }

    func makeTangemPayAccount(
        authorizer: TangemPayAuthorizer,
        signer: TangemSigner,
        userWalletId: UserWalletId,
        customerInfoManagementService: CustomerInfoManagementService
    ) -> TangemPayAccount {
        let tokenBalancesRepository = CommonTokenBalancesRepository(
            userWalletId: userWalletId
        )

        let withdrawTransactionService = CommonTangemPayWithdrawTransactionService(
            customerInfoManagementService: customerInfoManagementService,
            fiatItem: TangemPayUtilities.fiatItem,
            signer: signer
        )

        return TangemPayAccount(
            customerInfoManagementService: customerInfoManagementService,
            tokenBalancesRepository: tokenBalancesRepository,
            keysRepository: authorizer.keysRepository,
            withdrawTransactionService: withdrawTransactionService
        )
    }
}

extension TangemPayAccountBuilder {
    enum AuthorizerType {
        case availability
        case paeraCustomer
    }

    enum Error: LocalizedError {
        case authorizerNotFound
    }
}
