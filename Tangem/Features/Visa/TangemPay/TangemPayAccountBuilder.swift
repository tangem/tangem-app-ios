//
//  TangemPayAccountBuilder.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import TangemFoundation
import TangemVisa

struct TangemPayAccountBuilder {
    func makeTangemPayAccount(authorizerType: AuthorizerType, userWalletModel: UserWalletModel) async throws -> TangemPayAccount {
//        let authorizer: TangemPayAuthorizer? = switch authorizerType {
//        case .plain:
//            try await makeTangemPayAuthorizer(userWalletModel: userWalletModel)
//        case .availabilityService:
//            await makeTangemPayAuthorizerViaAvailabilityService(userWalletModel: userWalletModel)
//        }
//
//        guard let authorizer else {
//            throw Error.authorizerNotFound
//        }
//
//        return makeTangemPayAccount(authorizer: authorizer, userWalletModel: userWalletModel)
        throw Error.authorizerNotFound
    }

    func build(
        customerWalletAddress: String,
        customerInfo: VisaCustomerInfoResponse,
        userWalletId: UserWalletId,
        keysRepository: KeysRepository,
        signer: any TangemSigner,
        authorizationTokensHandler: TangemPayAuthorizationTokensHandler,
        customerInfoManagementService: CustomerInfoManagementService
    ) -> TangemPayAccount {
        let tokenBalancesRepository = CommonTokenBalancesRepository(userWalletId: userWalletId)

        let balancesService = CommonTangemPayBalanceService(
            customerInfoManagementService: customerInfoManagementService,
            tokenBalancesRepository: tokenBalancesRepository
        )

        let withdrawTransactionService = CommonTangemPayWithdrawTransactionService(
            customerInfoManagementService: customerInfoManagementService,
            fiatItem: TangemPayUtilities.fiatItem,
            signer: signer
        )

        return TangemPayAccount(
            customerWalletId: userWalletId.stringValue,
            customerWalletAddress: customerWalletAddress,
            customerInfo: customerInfo,
            keysRepository: keysRepository,
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
