//
//  BackendAuthenticationRegistrar.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import class Alamofire.Interceptor
import struct Foundation.Data
import TangemBackendAuthentication
import TangemFoundation
import TangemMobileWalletSdk
import class TangemNetworkUtils.TangemProvider
import enum TangemSdk.EllipticCurve

enum BackendAuthenticationRegistrar {
    @Injected(\.keysManager) private static var keysManager: KeysManager

    static func configure() {
        guard FeatureProvider.isAvailable(.backendAuthentication) else {
            return
        }

        BackendAuthenticationAssembly.configure(
            BackendAuthenticationAssembly.Configuration(
                baseURL: AppEnvironment.current.backendAuthenticationBaseUrl,
                appPrivateKey: keysManager.authServiceKey,
                provider: TangemProvider<BackendAuthenticationTarget>(configuration: .ephemeralConfiguration),
                userWalletProvider: TangemProvider<UserWalletTarget>(
                    configuration: .ephemeralConfiguration,
                    requestInterceptor: Alamofire.Interceptor(
                        adapter: BackendAuthenticationAssembly.requestAdapter,
                        retrier: BackendAuthenticationAssembly.requestRetrier
                    )
                )
            )
        )
    }

    static func registerDevice() async {
        guard FeatureProvider.isAvailable(.backendAuthentication) else {
            return
        }

        let registerDevice = BackendAuthenticationAssembly.registerDevice

        do {
            try await registerDevice()
            AppLogger.info("Device registration succeeded")
        } catch {
            AppLogger.error("Device registration failed", error: error)
        }
    }

    static func registerNewMobileWallet(_ userWalletModel: some UserWalletModel) {
        guard
            FeatureProvider.isAvailable(.backendAuthentication),
            userWalletModel.isMobileWallet
        else {
            return
        }

        let mobileWalletSDK = CommonMobileWalletSdk()

        guard let context = try? mobileWalletSDK.validate(auth: .none, for: userWalletModel.userWalletId) else {
            assertionFailure("Expected a newly created mobile wallet to always be unprotected. Developer mistake.")
            return
        }

        guard let secp256k1PublicKey = try? userWalletModel.keysRepository.masterKeyPublicKey(curve: .secp256k1) else {
            assertionFailure("Expected a newly created mobile wallet to always have a secp256k1 key. Developer mistake.")
            return
        }

        registerUnlockedMobileWallet(
            id: userWalletModel.userWalletId,
            context: context,
            mobileWalletSDK: mobileWalletSDK,
            secp256k1PublicKey: secp256k1PublicKey
        )
    }

    static func registerUnlockedMobileWallet(
        id: UserWalletId,
        context: MobileWalletContext,
        mobileWalletSDK: some MobileWalletSdk,
        secp256k1PublicKey: Data? = nil
    ) {
        guard FeatureProvider.isAvailable(.backendAuthentication) else {
            return
        }

        let signer = MobileUserWalletRegistrationSigner(
            context: context,
            secp256k1PublicKey: secp256k1PublicKey,
            mobileWalletSDK: mobileWalletSDK
        )

        Task {
            do {
                try await BackendAuthenticationAssembly.registerUserWallet(id: id, signer: signer)
                AppLogger.info("User wallet registration succeeded")
            } catch {
                AppLogger.error("User wallet registration failed", error: error)
            }
        }
    }

    static func unregisterMobileWalletIfNeeded(_ userWalletModel: some UserWalletModel) {
        guard
            FeatureProvider.isAvailable(.backendAuthentication),
            userWalletModel.isMobileWallet
        else {
            return
        }

        Task {
            do {
                try await BackendAuthenticationAssembly.unregisterUserWallet(id: userWalletModel.userWalletId)
                AppLogger.info("User wallet unregistration succeeded")
            } catch {
                AppLogger.error("User wallet unregistration failed", error: error)
            }
        }
    }
}

private extension UserWalletModel {
    var isMobileWallet: Bool {
        !config.hasFeature(.nfcInteraction)
    }
}
