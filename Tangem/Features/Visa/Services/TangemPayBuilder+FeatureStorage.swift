//
//  VisaBuilder+FeatureStorage.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import TangemPay

extension TangemPayAvailabilityServiceBuilder {
    @Injected(\.keysManager)
    private static var keysManager: KeysManager

    init() {
        self = TangemPayAvailabilityServiceBuilder(
            apiType: FeatureStorage.instance.tangemPayAPIType,
            bffStaticToken: Self.keysManager.bffStaticToken
        )
    }
}

extension TangemPayAuthorizationServiceBuilder {
    @Injected(\.tangemPayAuthorizationTokensRepository)
    private static var tangemPayAuthorizationTokensRepository: TangemPayAuthorizationTokensRepository

    @Injected(\.keysManager)
    private static var keysManager: KeysManager

    init() {
        self = TangemPayAuthorizationServiceBuilder(
            apiType: FeatureStorage.instance.tangemPayAPIType,
            authorizationTokensRepository: Self.tangemPayAuthorizationTokensRepository,
            bffStaticToken: Self.keysManager.bffStaticToken
        )
    }
}

extension TangemPayCustomerServiceBuilder {
    @Injected(\.keysManager)
    private static var keysManager: KeysManager

    init() {
        self = TangemPayCustomerServiceBuilder(
            apiType: FeatureStorage.instance.tangemPayAPIType,
            bffStaticToken: Self.keysManager.bffStaticToken
        )
    }
}
