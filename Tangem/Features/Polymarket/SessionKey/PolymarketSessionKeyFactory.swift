//
//  PolymarketSessionKeyFactory.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation
import TangemPolymarket

struct PolymarketSessionKeyFactory {
    static func isFastTradingAvailable() -> Bool {
        FeatureProvider.isAvailable(.polymarketFastOrders)
    }

    static func isFastTradingPauseAvailable() -> Bool {
        isFastTradingAvailable() && FeatureProvider.isAvailable(.polymarketFastTradingPause)
    }

    private let services = PolymarketOnboardingServicesFactory.makeDefault()

    func makeKeyStore() -> PolymarketSessionKeyStore {
        CommonPolymarketSessionKeyStore()
    }

    func makeOwnerKeySigningRouter(for userWalletModel: any UserWalletModel) -> PolymarketOrderSigningRouting {
        makeRouter(for: userWalletModel, isEligible: false, interruptedAuthorizations: CommonPolymarketInterruptedAuthorizationStore())
    }

    func makeOrderDigestSigner(for userWalletModel: any UserWalletModel) -> PolymarketOrderDigestSigning {
        PolymarketSessionKeyDigestSigner(userWalletId: userWalletModel.userWalletId, keyStore: makeKeyStore())
    }

    func makeManager(
        for userWalletModel: any UserWalletModel,
        signingRouter: PolymarketOrderSigningRouting,
        interruptedAuthorizations: PolymarketInterruptedAuthorizationStore
    ) -> PolymarketSessionKeyManaging {
        let walletId = userWalletModel.userWalletId.stringValue

        return CommonPolymarketSessionKeyManager(
            userWalletId: userWalletModel.userWalletId,
            keyStore: makeKeyStore(),
            deviceIdProvider: KeychainPolymarketDeviceIdProvider(),
            deviceName: Self.deviceName,
            depositWalletResolver: PolymarketDepositWalletResolver(
                walletService: services.makeWalletService(walletId: walletId),
                ownerAddressProvider: PolymarketOnboardingFactory().makeOwnerAddressProvider(for: userWalletModel)
            ),
            relayerService: services.makeRelayerService(),
            signer: CurrentSignerBatchSigner(userWalletModel: userWalletModel),
            sessionKeyService: services.makeSessionKeyService(walletId: walletId),
            ownerCredentials: CommonPolymarketOwnerCredentialsObtainer(
                userWalletId: userWalletModel.userWalletId,
                clobService: services.makeOwnerCLOBService(userWalletId: userWalletModel.userWalletId),
                credentialsRepository: CommonPolymarketCredentialsRepository()
            ),
            signingRouter: signingRouter,
            interruptedAuthorizations: interruptedAuthorizations,
            serverClock: InjectedValues[\.polymarketServerClock]
        )
    }

    @MainActor
    func makeFastTradingContext(for userWalletModel: any UserWalletModel) -> PolymarketFastTradingContext {
        let interruptedAuthorizations = CommonPolymarketInterruptedAuthorizationStore()
        let signingRouter = makeRouter(for: userWalletModel, isEligible: true, interruptedAuthorizations: interruptedAuthorizations)

        let service = CommonPolymarketFastTradingService(
            userWalletId: userWalletModel.userWalletId,
            manager: makeManager(for: userWalletModel, signingRouter: signingRouter, interruptedAuthorizations: interruptedAuthorizations),
            keyStore: makeKeyStore(),
            deviceIdProvider: KeychainPolymarketDeviceIdProvider(),
            clobService: services.makeOwnerCLOBService(userWalletId: userWalletModel.userWalletId),
            credentialsRepository: CommonPolymarketCredentialsRepository(),
            ownerAddressProvider: CommonPolymarketOwnerAddressProvider(keysRepository: userWalletModel.keysRepository),
            bannerDismissals: AppSettings.shared,
            signingRouter: signingRouter
        )

        return PolymarketFastTradingContext(signingRouter: signingRouter, service: service)
    }

    func makeOnboardingFastTrading(
        for userWalletModel: any UserWalletModel,
        service: any PolymarketFastTradingOperating & PolymarketFastTradingFailureReporting
    ) -> PolymarketOnboardingFastTrading {
        CommonPolymarketOnboardingFastTrading(
            authorizations: PolymarketSessionKeyAuthorizations(
                userWalletId: userWalletModel.userWalletId,
                keyStore: makeKeyStore(),
                serverClock: InjectedValues[\.polymarketServerClock]
            ),
            authorize: { batch, grant in
                try await service.authorize(presigned: batch, grant: grant)
            },
            report: { failure in
                await service.reportFailure(failure)
            }
        )
    }

    static var deviceName: String {
        DeviceInfoProvider.Subject.deviceModel.payload
    }
}

// MARK: - Private implementation

private extension PolymarketSessionKeyFactory {
    func makeRouter(
        for userWalletModel: any UserWalletModel,
        isEligible: Bool,
        interruptedAuthorizations: PolymarketInterruptedAuthorizationStore
    ) -> CommonPolymarketOrderSigningRouter {
        let userWalletId = userWalletModel.userWalletId
        let keyStore = makeKeyStore()

        return CommonPolymarketOrderSigningRouter(
            userWalletId: userWalletId,
            isEligible: isEligible,
            keyStore: keyStore,
            sessionCredentialsProvider: CommonPolymarketSessionCredentialsProvider(
                userWalletId: userWalletId,
                keyStore: keyStore,
                clobService: services.makeSessionKeyCLOBService()
            ),
            clobService: services.makeOwnerCLOBService(userWalletId: userWalletId),
            sessionKeyService: services.makeSessionKeyService(walletId: userWalletId.stringValue),
            credentialsRepository: CommonPolymarketCredentialsRepository(),
            ownerAddressProvider: CommonPolymarketOwnerAddressProvider(keysRepository: userWalletModel.keysRepository),
            interruptedAuthorizations: interruptedAuthorizations
        )
    }
}

// MARK: - Owner signing

private extension PolymarketSessionKeyFactory {
    struct CurrentSignerBatchSigner: PolymarketBatchesSigning {
        weak var userWalletModel: (any UserWalletModel)?

        func sign(
            _ batches: [PolymarketRelayedBatch.Unsigned],
            ownerAuthTimestamp: String?,
            as ownerAddress: String
        ) async throws(PolymarketSigningError) -> PolymarketSignedBatches {
            guard let userWalletModel else {
                throw .cancelled
            }

            let signer = PolymarketBatchSigner(keysRepository: userWalletModel.keysRepository, signer: userWalletModel.signer)

            return try await signer.sign(batches, ownerAuthTimestamp: ownerAuthTimestamp, as: ownerAddress)
        }
    }
}
