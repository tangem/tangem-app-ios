//
//  BackendAuthenticationAssembly.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

public import struct Foundation.Data
public import struct Foundation.URL
private import os.lock
public import protocol Alamofire.RequestAdapter
public import protocol Alamofire.RequestRetrier
public import class Moya.MoyaProvider
private import struct TangemFoundation.DeviceInfo

public enum BackendAuthenticationAssembly {
    public static let registerDeviceUseCase: RegisterDeviceUseCase = Self.makeRegisterDeviceUseCase()

    public static let requestAdapter: some Alamofire.RequestAdapter = Self.dPoPRequestAdapter
    public static let requestRetrier: some Alamofire.RequestRetrier = Self.renewSessionTokensRequestRetrier

    public static let storageCleaner: BackendAuthenticationStorageCleaner = Self.makeStorageCleaner()
}

// MARK: - Configuration

public extension BackendAuthenticationAssembly {
    struct Configuration: Sendable {
        public let baseURL: URL
        public let appPrivateKey: String
        public let provider: MoyaProvider<BackendAuthenticationTarget>

        public init(baseURL: URL, appPrivateKey: String, provider: MoyaProvider<BackendAuthenticationTarget>) {
            self.baseURL = baseURL
            self.appPrivateKey = appPrivateKey
            self.provider = provider
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

    private static let deviceKeyManager = DeviceKeyManager(privateKeyRepository: Self.devicePrivateKeyRepository)
    private static let dPoPProofGenerator = DPoPProofGenerator(deviceKeyManager: Self.deviceKeyManager)
    private static let nonceDecryptor = SecurityNonceDecryptor(appPrivateKey: Self.configuration.appPrivateKey)
    private static let appAttestService = FakeAppAttestService()

    private static let renewSessionTokensUseCase: RenewSessionTokensUseCase = {
        let sessionAuthenticationClient = MoyaSessionAuthenticationClient(
            provider: Self.configuration.provider,
            baseURL: Self.configuration.baseURL,
            dPoPProofGenerator: Self.dPoPProofGenerator
        )

        return RenewSessionTokensUseCase(
            registerDevice: Self.registerDeviceUseCase.callAsFunction,
            appAttestService: Self.appAttestService,
            sessionAuthenticationClient: sessionAuthenticationClient,
            sessionTokensRepository: Self.sessionTokensRepository,
            deviceKeyManager: Self.deviceKeyManager,
            nonceDecryptor: Self.nonceDecryptor,
            deviceMetadataProvider: DeviceMetadata.default
        )
    }()

    private static let dPoPRequestAdapter = DPoPRequestAdapter(
        renewSessionTokensUseCase: Self.renewSessionTokensUseCase,
        sessionTokensRepository: Self.sessionTokensRepository,
        dPoPProofGenerator: Self.dPoPProofGenerator
    )

    private static let renewSessionTokensRequestRetrier = RenewSessionTokensRequestRetrier(
        renewSessionTokensUseCase: Self.renewSessionTokensUseCase
    )

    private static func makeRegisterDeviceUseCase() -> RegisterDeviceUseCase {
        let deviceRegistrationClient = MoyaDeviceRegistrationClient(
            provider: Self.configuration.provider,
            baseURL: Self.configuration.baseURL
        )

        return RegisterDeviceUseCase(
            appAttestService: Self.appAttestService,
            deviceRegistrationClient: deviceRegistrationClient,
            sessionTokensRepository: Self.sessionTokensRepository,
            deviceRegistrationStatusRepository: UserDefaultsDeviceRegistrationStatusRepository(),
            deviceKeyManager: Self.deviceKeyManager,
            nonceDecryptor: Self.nonceDecryptor,
            deviceMetadataProvider: DeviceMetadata.default
        )
    }

    private static func makeStorageCleaner() -> BackendAuthenticationStorageCleaner {
        BackendAuthenticationStorageCleaner(
            devicePrivateKeyRepository: devicePrivateKeyRepository,
            sessionTokensRepository: sessionTokensRepository
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
