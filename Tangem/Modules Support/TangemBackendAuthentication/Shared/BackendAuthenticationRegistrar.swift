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
                ),
                logger: BackendAuthLogger
            )
        )
    }

    static func registerDevice() async {
        guard FeatureProvider.isAvailable(.backendAuthentication) else {
            return
        }

        let registerDevice = BackendAuthenticationAssembly.registerDevice

        do {
            let sessionTokens = try await registerDevice()
            BackendAuthLogger.info(sessionTokens == nil ? "Device already registered" : "Device registration succeeded")
        } catch {
            BackendAuthLogger.error("Device registration failed", error: error)
        }
    }

    static func registerNewMobileWallet(_ userWalletModel: some UserWalletModel) {
        guard FeatureProvider.isAvailable(.backendAuthentication) else {
            return
        }

        guard userWalletModel.isMobileWallet else {
            let errorMessage = "Expected to receive a mobile wallet, got cold instead. Developer mistake."
            BackendAuthLogger.warning(errorMessage)
            assertionFailure(errorMessage)
            return
        }

        let mobileWalletSDK = CommonMobileWalletSdk()

        let context: MobileWalletContext

        do {
            context = try mobileWalletSDK.validate(auth: .none, for: userWalletModel.userWalletId)
        } catch {
            let errorMessage = "Expected a newly created mobile wallet to always be unprotected. Developer mistake."
            BackendAuthLogger.error(errorMessage, error: error)
            assertionFailure(errorMessage)
            return
        }

        let secp256k1PublicKey: Data

        do {
            secp256k1PublicKey = try userWalletModel.keysRepository.masterKeyPublicKey(curve: .secp256k1)
        } catch {
            let errorMessage = "Expected a newly created mobile wallet to always have a secp256k1 key. Developer mistake."
            BackendAuthLogger.error(errorMessage, error: error)
            assertionFailure(errorMessage)
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
                try await BackendAuthenticationAssembly.registerUserWallet(id: id, recoveryEnrollment: nil, signer: signer)
                BackendAuthLogger.info("Registered user wallet \(id.stringValue)")
            } catch {
                BackendAuthLogger.error("Failed to register user wallet \(id.stringValue)", error: error)
            }
        }
    }

    static func unregisterUserWalletIfNeeded(_ userWalletModel: some UserWalletModel) {
        guard FeatureProvider.isAvailable(.backendAuthentication) else {
            return
        }

        let id = userWalletModel.userWalletId

        Task {
            do {
                try await BackendAuthenticationAssembly.unregisterUserWallet(id: id)
                BackendAuthLogger.info("Unregistered user wallet \(id.stringValue)")
            } catch {
                BackendAuthLogger.error("Failed to unregister user wallet \(id.stringValue)", error: error)
            }
        }
    }
}

private extension UserWalletModel {
    var isMobileWallet: Bool {
        !config.hasFeature(.nfcInteraction)
    }
}
