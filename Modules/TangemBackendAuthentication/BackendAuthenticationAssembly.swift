//
//  BackendAuthenticationAssembly.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

public import struct Foundation.Data
public import class Foundation.JSONDecoder
public import struct Foundation.URL
private import os.lock
public import protocol Alamofire.RequestAdapter
public import protocol Alamofire.RequestRetrier
public import class Moya.MoyaProvider
public import struct TangemLogger.Logger
private import TangemFoundation

public enum BackendAuthenticationAssembly {
    public static let registerDevice: RegisterDeviceUseCase = Self.makeRegisterDeviceUseCase()

    public static let obtainUserWalletRegistrationNonce: ObtainUserWalletRegistrationNonceUseCase =
        Self.makeObtainUserWalletRegistrationNonceUseCase()

    public static let attestUserWallet: AttestUserWalletUseCase =
        Self.makeAttestUserWalletUseCase()

    public static let submitUserWalletRegistration: SubmitUserWalletRegistrationUseCase =
        Self.makeSubmitUserWalletRegistrationUseCase()

    public static let registerUserWallet: RegisterUserWalletUseCase = Self.makeRegisterUserWalletUseCase()

    public static let unregisterUserWallet: UnregisterUserWalletUseCase = Self.makeUnregisterUserWalletUseCase()

    public static let requestAdapter: any Alamofire.RequestAdapter = Self.dPoPRequestAdapter
    public static let requestRetrier: any Alamofire.RequestRetrier = Self.renewSessionTokensRequestRetrier

    public static let storageCleaner: BackendAuthenticationStorageCleaner = Self.makeStorageCleaner()
}

// MARK: - Configuration

public extension BackendAuthenticationAssembly {
    struct Configuration: Sendable {
        let baseURL: URL
        let appPrivateKey: String
        let provider: MoyaProvider<BackendAuthenticationTarget>
        let userWalletProvider: @Sendable () -> MoyaProvider<UserWalletTarget>
        let logger: Logger

        public init(
            baseURL: URL,
            appPrivateKey: String,
            provider: MoyaProvider<BackendAuthenticationTarget>,
            userWalletProvider: @escaping @Sendable @autoclosure () -> MoyaProvider<UserWalletTarget>,
            logger: Logger
        ) {
            self.baseURL = baseURL
            self.appPrivateKey = appPrivateKey
            self.provider = provider
            self.userWalletProvider = userWalletProvider
            self.logger = logger
        }
    }

    private static let configurationLock = OSAllocatedUnfairLock(initialState: Configuration?.none)

    fileprivate static var configuration: Configuration {
        guard let configuration = configurationLock.withLock(\.self) else {
            preconditionFailure("BackendAuthenticationAssembly.configure(_:) must be called before use.")
        }
        return configuration
    }

    static func configure(_ configuration: Configuration) {
        configurationLock.withLock {
            precondition($0 == nil, "BackendAuthenticationAssembly.configure(_:) must be called exactly once.")
            $0 = configuration
        }
    }
}

// MARK: - Factory methods

extension BackendAuthenticationAssembly {
    private static let sessionTokensRepository = KeychainSessionTokensRepository(
        keychainRepository: SecurityKeychainRepository(
            keychainService: Keychain.service,
            keychainAccount: "sessionTokens"
        )
    )

    private static let devicePrivateKeyRepository = SecureEnclaveDevicePrivateKeyRepository(
        keychainRepository: SecurityKeychainRepository(
            keychainService: Keychain.service,
            keychainAccount: "deviceKey"
        )
    )

    private static let userWalletRegistrationStatusRepository = UserDefaultsUserWalletRegistrationStatusRepository()
    private static let deviceRegistrationStatusRepository = UserDefaultsDeviceRegistrationStatusRepository()

    private static let jsonDecoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .customISO8601
        return decoder
    }()

    private static let userWalletRegistrationClient = MoyaUserWalletRegistrationClient(
        provider: Self.configuration.userWalletProvider(),
        nonceProvider: Self.configuration.provider,
        baseURL: Self.configuration.baseURL,
        decoder: Self.jsonDecoder
    )

    private static let deviceKeyManager = DeviceKeyManager(privateKeyRepository: Self.devicePrivateKeyRepository)
    private static let dPoPProofGenerator = DPoPProofGenerator(deviceKeyManager: Self.deviceKeyManager)
    private static let nonceDecryptor = SecurityNonceDecryptor(appPrivateKey: Self.configuration.appPrivateKey)
    private static let appAttestService = FakeAppAttestService()

    private static let renewSessionTokensUseCase: RenewSessionTokensUseCase = {
        let sessionAuthenticationClient = MoyaSessionAuthenticationClient(
            dPoPProofGenerator: Self.dPoPProofGenerator,
            provider: Self.configuration.provider,
            baseURL: Self.configuration.baseURL,
            decoder: Self.jsonDecoder
        )

        return RenewSessionTokensUseCase(
            registerDevice: Self.registerDevice.callAsFunction,
            appAttestService: Self.appAttestService,
            sessionAuthenticationClient: sessionAuthenticationClient,
            sessionTokensRepository: Self.sessionTokensRepository,
            deviceRegistrationStatusRepository: Self.deviceRegistrationStatusRepository,
            deviceKeyManager: Self.deviceKeyManager,
            nonceDecryptor: Self.nonceDecryptor,
            deviceMetadataProvider: DeviceMetadata.default,
            logger: Self.configuration.logger
        )
    }()

    private static let dPoPRequestAdapter = DPoPRequestAdapter(
        renewSessionTokensUseCase: Self.renewSessionTokensUseCase,
        sessionTokensRepository: Self.sessionTokensRepository,
        dPoPProofGenerator: Self.dPoPProofGenerator,
        logger: Self.configuration.logger
    )

    private static let renewSessionTokensRequestRetrier = RenewSessionTokensRequestRetrier(
        renewSessionTokensUseCase: Self.renewSessionTokensUseCase,
        logger: Self.configuration.logger
    )

    private static func makeRegisterDeviceUseCase() -> RegisterDeviceUseCase {
        let deviceRegistrationClient = MoyaDeviceRegistrationClient(
            provider: Self.configuration.provider,
            baseURL: Self.configuration.baseURL,
            decoder: Self.jsonDecoder
        )

        return RegisterDeviceUseCase(
            appAttestService: Self.appAttestService,
            registrationClient: deviceRegistrationClient,
            registrationStatusRepository: Self.deviceRegistrationStatusRepository,
            sessionTokensRepository: Self.sessionTokensRepository,
            deviceKeyManager: Self.deviceKeyManager,
            nonceDecryptor: Self.nonceDecryptor,
            deviceMetadataProvider: DeviceMetadata.default,
            logger: Self.configuration.logger
        )
    }

    private static func makeObtainUserWalletRegistrationNonceUseCase() -> ObtainUserWalletRegistrationNonceUseCase {
        ObtainUserWalletRegistrationNonceUseCase(
            registerDevice: registerDevice.callAsFunction,
            appAttestService: appAttestService,
            registrationClient: userWalletRegistrationClient,
            registrationStatusRepository: userWalletRegistrationStatusRepository,
            deviceKeyManager: deviceKeyManager,
            nonceDecryptor: nonceDecryptor,
            logger: configuration.logger
        )
    }

    private static func makeAttestUserWalletUseCase() -> AttestUserWalletUseCase {
        AttestUserWalletUseCase(
            registrationStatusRepository: userWalletRegistrationStatusRepository,
            deviceMetadataProvider: DeviceMetadata.default
        )
    }

    private static func makeSubmitUserWalletRegistrationUseCase() -> SubmitUserWalletRegistrationUseCase {
        SubmitUserWalletRegistrationUseCase(
            registrationClient: userWalletRegistrationClient,
            registrationStatusRepository: userWalletRegistrationStatusRepository,
            sessionTokensRepository: sessionTokensRepository
        )
    }

    private static func makeRegisterUserWalletUseCase() -> RegisterUserWalletUseCase {
        RegisterUserWalletUseCase(
            obtainNonce: obtainUserWalletRegistrationNonce.callAsFunction,
            attestUserWallet: { id, nonce, signer async throws(AttestUserWalletError) in
                try await Self.attestUserWallet(id: id, nonce: nonce, signer: signer)
            },
            submitRegistration: submitUserWalletRegistration.callAsFunction,
            logger: configuration.logger
        )
    }

    private static func makeUnregisterUserWalletUseCase() -> UnregisterUserWalletUseCase {
        UnregisterUserWalletUseCase(
            registrationClient: userWalletRegistrationClient,
            registrationStatusRepository: userWalletRegistrationStatusRepository,
            sessionTokensRepository: sessionTokensRepository
        )
    }

    private static func makeStorageCleaner() -> BackendAuthenticationStorageCleaner {
        BackendAuthenticationStorageCleaner(
            devicePrivateKeyRepository: devicePrivateKeyRepository,
            sessionTokensRepository: sessionTokensRepository,
            logger: configuration.logger
        )
    }
}

extension BackendAuthenticationAssembly {
    private enum Keychain {
        static let service = "com.tangem.backendAuthentication"
    }
}

// [REDACTED_TODO_COMMENT]

private struct FakeAppAttestService: AppAttestService {
    func generateAttestationToken(for requestData: Data) async throws(AppAttestServiceError) -> Data {
        throw AppAttestServiceError()
    }
}

private extension DeviceMetadata {
    static var `default`: DeviceMetadata {
        let deviceInfo = DeviceInfo()

        return DeviceMetadata(
            deviceModel: deviceInfo.device,
            os: deviceInfo.platform,
            osVersion: deviceInfo.systemVersion,
            appVersion: deviceInfo.version,
            userAgent: "Tangem/\(deviceInfo.version) (iOS \(deviceInfo.systemVersion); \(deviceInfo.device))",
            locale: deviceInfo.language,
            timezone: deviceInfo.timezone
        )
    }
}
