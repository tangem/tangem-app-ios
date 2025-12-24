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
