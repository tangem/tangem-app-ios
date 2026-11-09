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
    private static let routers = PolymarketWalletInstanceCache<CommonPolymarketOrderSigningRouter>()
    private static let fastTradingServices = PolymarketWalletInstanceCache<CommonPolymarketFastTradingService>()

    static func isFastTradingAvailable() -> Bool {
        FeatureProvider.isAvailable(.polymarketFastTrading)
    }

    static func removeInstances(for userWalletId: UserWalletId) {
        routers.removeInstance(for: userWalletId)
        fastTradingServices.removeInstance(for: userWalletId)
    }

    private let services = PolymarketOnboardingServicesFactory.makeDefault()

    func makeKeyStore() -> PolymarketSessionKeyStore {
        CommonPolymarketSessionKeyStore()
    }

    func makeSigningRouter(for userWalletModel: any UserWalletModel) -> PolymarketOrderSigningRouting {
        guard Self.isFastTradingAvailable() else {
            return makeRouter(for: userWalletModel, isEligible: false)
        }

        return Self.routers.instance(for: userWalletModel) {
            makeRouter(for: userWalletModel, isEligible: true)
        }
    }

    func makeOrderDigestSigner(for userWalletModel: any UserWalletModel) -> PolymarketOrderDigestSigning {
        PolymarketSessionKeyDigestSigner(userWalletId: userWalletModel.userWalletId, keyStore: makeKeyStore())
    }

    func makeManager(for userWalletModel: any UserWalletModel) -> PolymarketSessionKeyManaging {
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
                clobService: services.makeCLOBService(),
                credentialsRepository: CommonPolymarketCredentialsRepository()
            ),
            signingRouter: makeSigningRouter(for: userWalletModel),
            serverClock: InjectedValues[\.polymarketServerClock]
        )
    }

    @MainActor
    func makeFastTradingService(for userWalletModel: any UserWalletModel) -> PolymarketFastTradingServicing? {
        guard Self.isFastTradingAvailable() else {
            return nil
        }

        return Self.fastTradingServices.instance(for: userWalletModel) {
            CommonPolymarketFastTradingService(
                userWalletId: userWalletModel.userWalletId,
                manager: makeManager(for: userWalletModel),
                keyStore: makeKeyStore(),
                deviceIdProvider: KeychainPolymarketDeviceIdProvider(),
                clobService: services.makeCLOBService(),
                credentialsRepository: CommonPolymarketCredentialsRepository(),
                ownerAddressProvider: CommonPolymarketOwnerAddressProvider(keysRepository: userWalletModel.keysRepository),
                bannerDismissals: AppSettings.shared,
                refusalsPublisher: makeSigningRouter(for: userWalletModel).refusalsPublisher
            )
        }
    }

    func makeOnboardingFastTrading(for userWalletModel: any UserWalletModel) -> PolymarketOnboardingFastTrading? {
        guard Self.isFastTradingAvailable() else {
            return nil
        }

        return CommonPolymarketOnboardingFastTrading(
            userWalletId: userWalletModel.userWalletId,
            keyStore: makeKeyStore(),
            serverClock: InjectedValues[\.polymarketServerClock],
            authorize: { batch, grant in
                guard let service = await PolymarketSessionKeyFactory().makeFastTradingService(for: userWalletModel) else {
                    return
                }

                try await service.authorize(presigned: batch, grant: grant)
            }
        )
    }

    static var deviceName: String {
        DeviceInfoProvider.Subject.deviceModel.payload
    }
}

// MARK: - Private implementation

private extension PolymarketSessionKeyFactory {
    func makeRouter(for userWalletModel: any UserWalletModel, isEligible: Bool) -> CommonPolymarketOrderSigningRouter {
        let userWalletId = userWalletModel.userWalletId
        let keyStore = makeKeyStore()
        let clobService = services.makeCLOBService()

        return CommonPolymarketOrderSigningRouter(
            userWalletId: userWalletId,
            isEligible: isEligible,
            keyStore: keyStore,
            sessionCredentialsProvider: CommonPolymarketSessionCredentialsProvider(
                userWalletId: userWalletId,
                keyStore: keyStore,
                clobService: clobService
            ),
            clobService: clobService,
            sessionKeyService: services.makeSessionKeyService(walletId: userWalletId.stringValue),
            credentialsRepository: CommonPolymarketCredentialsRepository(),
            ownerAddressProvider: CommonPolymarketOwnerAddressProvider(keysRepository: userWalletModel.keysRepository)
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
