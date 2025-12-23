//
//  TangemPayAccountBuilder.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import TangemVisa

struct TangemPayAccountBuilder {
    func makeTangemPayAccount(authorizerType: AuthorizerType, userWalletModel: UserWalletModel) async throws -> TangemPayAccount {
        let authorizer: TangemPayAuthorizer? = switch authorizerType {
        case .plain:
            try await makeTangemPayAuthorizer(userWalletModel: userWalletModel)
        case .availabilityService:
            await makeTangemPayAuthorizerViaAvailabilityService(userWalletModel: userWalletModel)
        }

        guard let authorizer else {
            throw Error.authorizerNotFound
        }

        return makeTangemPayAccount(authorizer: authorizer, userWalletModel: userWalletModel)
    }
}

// MARK: - Private

private extension TangemPayAccountBuilder {
    /// Uses in `CommonUserWalletModel`
    func makeTangemPayAuthorizerViaAvailabilityService(userWalletModel: UserWalletModel) async -> TangemPayAuthorizer? {
        let customerWalletId = userWalletModel.userWalletId.stringValue
        let availabilityService = TangemPayAPIServiceBuilder().buildTangemPayAvailabilityService()

        let state: TangemPayAuthorizer.State? = await {
            do {
                if await !AppSettings.shared.tangemPayIsPaeraCustomer[customerWalletId, default: false] {
                    let isPaeraCustomer = try await availabilityService.isPaeraCustomer(
                        customerWalletId: customerWalletId
                    )

                    await MainActor.run {
                        AppSettings.shared.tangemPayIsPaeraCustomer[customerWalletId] = true
                        AppSettings.shared.tangemPayIsKYCHiddenForCustomerWalletId[
                            customerWalletId
                        ] = !isPaeraCustomer.isTangemPayEnabled
                    }
                }

                if let (customerWalletAddress, tokens) = TangemPayUtilities.getCustomerWalletAddressAndAuthorizationTokens(
                    customerWalletId: customerWalletId,
                    keysRepository: userWalletModel.keysRepository
                ) {
                    return .authorized(customerWalletAddress: customerWalletAddress, tokens: tokens)
                } else {
                    return .syncNeeded
                }
            } catch {
                if await AppSettings.shared.tangemPayIsPaeraCustomer[customerWalletId, default: false] {
                    return .unavailable
                } else {
                    return nil
                }
            }
        }()

        guard let state else {
            return nil
        }

        let authorizer = TangemPayAuthorizer(
            customerWalletId: customerWalletId,
            interactor: userWalletModel.tangemPayAuthorizingInteractor,
            keysRepository: userWalletModel.keysRepository,
            state: state
        )

        return authorizer
    }

    /// Uses in `TangemPayOfferViewModel`
    func makeTangemPayAuthorizer(userWalletModel: UserWalletModel) async throws -> TangemPayAuthorizer {
        let customerWalletId = userWalletModel.userWalletId.stringValue
        let authorizer = TangemPayAuthorizer(
            customerWalletId: customerWalletId,
            interactor: userWalletModel.tangemPayAuthorizingInteractor,
            keysRepository: userWalletModel.keysRepository,
            state: .unavailable
        )

        try await authorizer.authorizeWithCustomerWallet()

        await MainActor.run {
            AppSettings.shared.tangemPayIsPaeraCustomer[customerWalletId] = true
        }

        return authorizer
    }

    func makeTangemPayAccount(authorizer: TangemPayAuthorizer, userWalletModel: UserWalletModel) -> TangemPayAccount {
        let authorizationTokensHandler = TangemPayAuthorizationTokensHandlerBuilder()
            .buildTangemPayAuthorizationTokensHandler(
                customerWalletId: authorizer.customerWalletId,
                authorizationService: authorizer.authorizationService,
                setSyncNeeded: authorizer.setSyncNeeded,
                setUnavailable: authorizer.setUnavailable
            )

        let customerInfoManagementService = TangemPayCustomerInfoManagementServiceBuilder()
            .buildCustomerInfoManagementService(authorizationTokensHandler: authorizationTokensHandler)

        let tokenBalancesRepository = CommonTokenBalancesRepository(
            userWalletId: userWalletModel.userWalletId
        )

        let balancesService = CommonTangemPayBalanceService(
            customerInfoManagementService: customerInfoManagementService,
            tokenBalancesRepository: tokenBalancesRepository
        )

        let withdrawTransactionService = CommonTangemPayWithdrawTransactionService(
            customerInfoManagementService: customerInfoManagementService,
            fiatItem: TangemPayUtilities.fiatItem,
            signer: userWalletModel.signer
        )

        return TangemPayAccount(
            authorizer: authorizer,
            authorizationTokensHandler: authorizationTokensHandler,
            customerInfoManagementService: customerInfoManagementService,
            balancesService: balancesService,
            withdrawTransactionService: withdrawTransactionService
        )
    }
}

extension TangemPayAccountBuilder {
    enum AuthorizerType {
        case plain
        case availabilityService
    }

    enum Error: LocalizedError {
        case authorizerNotFound
    }
}
