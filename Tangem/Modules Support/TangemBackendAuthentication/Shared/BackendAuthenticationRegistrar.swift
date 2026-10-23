//
//  BackendAuthenticationRegistrar.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import struct Foundation.Data
import class LocalAuthentication.LAContext
import class Alamofire.Interceptor
import TangemBackendAuthentication
import TangemFoundation
import TangemMobileWalletSdk
import class TangemNetworkUtils.TangemProvider
import enum TangemSdk.EllipticCurve

enum BackendAuthenticationRegistrar {
    @Injected(\.keysManager) private static var keysManager: KeysManager

    static func configure() {
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
                analyticsReporter: CommonBackendAuthenticationAnalyticsReporter(),
                logger: BackendAuthLogger
            )
        )
    }

    static func registerDevice() async {
        let registerDevice = BackendAuthenticationAssembly.registerDevice

        do {
            let sessionTokens = try await registerDevice()
            let didRegisterDevice = sessionTokens != nil

            didRegisterDevice
                ? BackendAuthLogger.info("Device registration succeeded")
                : BackendAuthLogger.debug("Device has already been registered")
        } catch {
            BackendAuthLogger.error("Device registration failed", error: error)
        }
    }

    static func unregisterUserWallet(_ userWalletModel: some UserWalletModel) {
        let id = userWalletModel.userWalletId

        Task {
            do {
                try await BackendAuthenticationAssembly.unregisterUserWallet(id: id, shouldEraseSocialLoginData: false)
                BackendAuthLogger.info("Unregistered user wallet \(id.stringValue)")
            } catch {
                BackendAuthLogger.error("Failed to unregister user wallet \(id.stringValue)", error: error)
            }
        }
    }
}

// MARK: - Mobile wallet

extension BackendAuthenticationRegistrar {
    static func registerNewUnprotectedMobileWallet(_ userWalletModel: some UserWalletModel) {
        guard userWalletModel.assertIsMobileWallet() else {
            return
        }

        let mobileWalletSDK = CommonMobileWalletSdk()

        let context: MobileWalletContext

        do {
            context = try mobileWalletSDK.validate(auth: .none, for: userWalletModel.userWalletId)
        } catch {
            let errorMessage = "Expected a newly created mobile wallet to always be unprotected. Developer mistake"
            BackendAuthLogger.error(errorMessage, error: error)
            assertionFailure(errorMessage)
            return
        }

        let secp256k1PublicKey: Data

        do {
            secp256k1PublicKey = try userWalletModel.keysRepository.masterKeyPublicKey(curve: .secp256k1)
        } catch {
            let errorMessage = "Expected a newly created mobile wallet to always have a secp256k1 key. Developer mistake"
            BackendAuthLogger.error(errorMessage, error: error)
            assertionFailure(errorMessage)
            return
        }

        Self.registerMobileWallet(
            id: userWalletModel.userWalletId,
            context: context,
            trigger: .newUnprotectedCreation,
            mobileWalletSDK: mobileWalletSDK,
            secp256k1PublicKey: secp256k1PublicKey
        )
    }

    static func registerMobileWalletAfterBiometricUnlock(_ userWalletModel: some UserWalletModel, context laContext: LAContext) {
        guard userWalletModel.isMobileWallet else {
            return
        }

        let id = userWalletModel.userWalletId

        Task {
            let userWalletIsAlreadyRegistered = await BackendAuthenticationAssembly.retrieveUserWalletRegistrationStatus(id: id)
            let registrationTrigger = MobileWalletRegistrationTrigger.afterBiometricUnlock

            guard !userWalletIsAlreadyRegistered else {
                BackendAuthLogger.debug(
                    "Skipped registration of mobile wallet \(id.stringValue) \(registrationTrigger), already registered"
                )
                return
            }

            let mobileWalletSDK = CommonMobileWalletSdk()
            let context: MobileWalletContext

            do {
                context = try mobileWalletSDK.validate(auth: .biometrics(context: laContext), for: id)
            } catch {
                BackendAuthLogger.info(
                    """
                    Registration of the biometrically unlocked mobile wallet is skipped until \
                    the wallet is unlocked with its access code. Biometric access is unavailable due to: \(error)
                    """
                )
                return
            }

            Self.registerMobileWallet(id: id, context: context, trigger: registrationTrigger, mobileWalletSDK: mobileWalletSDK)
        }
    }

    static func registerMobileWalletAfterAccessCodeUpdated(_ userWalletModel: some UserWalletModel, accessCode: String) {
        guard userWalletModel.assertIsMobileWallet() else {
            return
        }

        let id = userWalletModel.userWalletId

        Task {
            let userWalletIsAlreadyRegistered = await BackendAuthenticationAssembly.retrieveUserWalletRegistrationStatus(id: id)
            let registrationTrigger = MobileWalletRegistrationTrigger.afterAccessCodeUpdated

            guard !userWalletIsAlreadyRegistered else {
                BackendAuthLogger.debug(
                    "Skipped registration of mobile wallet \(id.stringValue) \(registrationTrigger), already registered"
                )
                return
            }

            let mobileWalletSDK = CommonMobileWalletSdk()
            let context: MobileWalletContext

            do {
                context = try mobileWalletSDK.validate(auth: .accessCode(accessCode), for: id)
            } catch {
                let errorMessage = "Fresh access code is expected to be valid for a given mobile wallet. Developer mistake"
                BackendAuthLogger.error(errorMessage, error: error)
                assertionFailure(errorMessage)
                return
            }

            Self.registerMobileWallet(id: id, context: context, trigger: registrationTrigger, mobileWalletSDK: mobileWalletSDK)
        }
    }

    static func registerMobileWalletAfterAutomaticUnlock(id: UserWalletId, context: MobileWalletContext) {
        registerMobileWallet(id: id, context: context, trigger: .afterAutomaticUnlock, mobileWalletSDK: CommonMobileWalletSdk())
    }

    static func registerMobileWalletAfterAccessCodeUnlock(id: UserWalletId, context: MobileWalletContext) {
        registerMobileWallet(id: id, context: context, trigger: .afterAccessCodeUnlock, mobileWalletSDK: CommonMobileWalletSdk())
    }

    static func registerNewUnprotectedSocialMobileWallet(
        id: UserWalletId,
        keys: [KeyInfo],
        recoveryEnrollment: UserWalletRecoveryEnrollment?
    ) async throws {
        let mobileWalletSDK = CommonMobileWalletSdk()
        let context = try mobileWalletSDK.validate(auth: .none, for: id)
        let secp256k1PublicKey = try CommonKeysRepository(keys: .mobileWallet(keys: keys))
            .masterKeyPublicKey(curve: .secp256k1)

        let signer = MobileUserWalletRegistrationSigner(
            context: context,
            secp256k1PublicKey: secp256k1PublicKey,
            mobileWalletSDK: mobileWalletSDK
        )

        try await BackendAuthenticationAssembly.registerMobileUserWallet(
            id: id,
            recoveryEnrollment: recoveryEnrollment,
            signer: signer
        )
        BackendAuthLogger.info("Registered social mobile wallet \(id.stringValue.masked())")
    }

    static func unregisterSocialMobileWallet(id: UserWalletId) async throws {
        try await BackendAuthenticationAssembly.unregisterUserWallet(id: id, shouldEraseSocialLoginData: true)
        BackendAuthLogger.info("Unregistered social mobile wallet \(id.stringValue.masked())")
    }

    private static func registerMobileWallet(
        id: UserWalletId,
        context: MobileWalletContext,
        trigger: MobileWalletRegistrationTrigger,
        mobileWalletSDK: some MobileWalletSdk,
        secp256k1PublicKey: Data? = nil
    ) {
        let signer = MobileUserWalletRegistrationSigner(
            context: context,
            secp256k1PublicKey: secp256k1PublicKey,
            mobileWalletSDK: mobileWalletSDK
        )

        Task {
            do {
                try await BackendAuthenticationAssembly.registerMobileUserWallet(id: id, recoveryEnrollment: nil, signer: signer)
                BackendAuthLogger.info("Registered mobile wallet \(id.stringValue) \(trigger)")
            } catch {
                BackendAuthLogger.error("Failed to register mobile wallet \(id.stringValue) \(trigger)", error: error)
            }
        }
    }

    /// - Note: Methods of the non-isolated `BackendAuthenticationRegistrar` are implicitly `nonisolated`,
    /// and Swift 5 mode runs such `async` ones as Swift 6.2 `@concurrent`;
    /// `nonisolated(nonsending)` keeps the non-Sendable `userWalletModel` on the caller's actor
    nonisolated(nonsending) static func prepareMobileWalletForColdUpgrade(_ userWalletModel: some UserWalletModel) async {
        guard userWalletModel.assertIsMobileWallet() else {
            return
        }

        await BackendAuthenticationAssembly.clearUserWalletRegistrationStatus(id: userWalletModel.userWalletId)
        BackendAuthLogger.info("Mobile wallet on-device registration status cleared before cold wallet upgrade")
    }
}

private extension BackendAuthenticationRegistrar {
    enum MobileWalletRegistrationTrigger: CustomStringConvertible {
        case newUnprotectedCreation
        case afterAutomaticUnlock
        case afterAccessCodeUnlock
        case afterBiometricUnlock
        case afterAccessCodeUpdated

        var description: String {
            switch self {
            case .newUnprotectedCreation: "on new unprotected wallet creation"
            case .afterAutomaticUnlock: "after automatic unlock"
            case .afterAccessCodeUnlock: "after access code unlock"
            case .afterBiometricUnlock: "after biometric unlock"
            case .afterAccessCodeUpdated: "after access code update"
            }
        }
    }
}

private extension UserWalletModel {
    var isMobileWallet: Bool {
        !config.hasFeature(.nfcInteraction)
    }

    func assertIsMobileWallet(file: StaticString = #fileID, line: UInt = #line, function: StaticString = #function) -> Bool {
        if isMobileWallet {
            return true
        }

        let errorMessage = "Expected to receive a mobile wallet, got cold instead. Developer mistake"
        BackendAuthLogger.warning(file: file, line: line, function: function, errorMessage)
        assertionFailure(errorMessage, file: file, line: line)

        return false
    }
}
