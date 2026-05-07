//
//  WalletKitClientFactory.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import ReownWalletKit
import WalletConnectRelay
import WalletConnectKMS
import WalletConnectUtils
import enum TangemFoundation.AppEnvironment

enum WalletKitClientFactory {
    @Injected(\.keysManager) private static var keysManager: KeysManager

    static func make() -> ReownWalletKit.WalletKitClient {
        configureNetworking()
        overrideRelayWithSafeNetworkMonitor()
        configureWalletKit()

        return WalletKit.instance
    }

    private static func configureNetworking() {
        Networking.configure(
            groupIdentifier: AppEnvironment.current.suiteName,
            // [REDACTED_TODO_COMMENT]
//            projectId: keysManager.walletConnectProjectId,
            projectId: "790bb4f309edf20d4218236296448c00",
            socketFactory: WalletConnectV2DefaultSocketFactory(),
            socketConnectionType: .automatic
        )
    }

    /// Overrides `Relay.instance` with a `RelayClient` that uses `SafeNetworkMonitor`
    /// instead of the library's default `NetworkMonitor`.
    ///
    /// This fixes a critical crash in `WalletPairService.resolveNetworkConnectionStatus()`
    /// where a `CheckedContinuation` can be resumed twice due to rapid `NWPathMonitor`
    /// re-evaluations. `SafeNetworkMonitor` emits the current value immediately and debounces
    /// subsequent updates, so the second emission cannot arrive inside the cancellation race
    /// window. Duplicate statuses are filtered as an additional guard.
    ///
    /// Must be called after `Networking.configure()` (which sets the config) and before
    /// `WalletKit.configure()` (which first accesses `Relay.instance`).
    private static func overrideRelayWithSafeNetworkMonitor() {
        let groupIdentifier = AppEnvironment.current.suiteName

        guard let keyValueStorage = UserDefaults(suiteName: groupIdentifier) else {
            assertionFailure("Could not instantiate UserDefaults for group identifier \(groupIdentifier)")
            return
        }

        let keychainStorage = KeychainStorage(serviceIdentifier: "com.walletconnect.sdk", accessGroup: groupIdentifier)
        let logger = ConsoleLogger(prefix: "WC Network Monitor", loggingLevel: .off)

        Relay.instance = RelayClientFactory.create(
            relayHost: "relay.walletconnect.org",
            projectId: keysManager.walletConnectProjectId,
            keyValueStorage: keyValueStorage,
            keychainStorage: keychainStorage,
            socketFactory: WalletConnectV2DefaultSocketFactory(),
            socketConnectionType: .automatic,
            networkMonitor: SafeNetworkMonitor(),
            logger: logger
        )
    }

    private static func configureWalletKit() {
        WalletKit.configure(
            metadata: .tangem,
            crypto: WalletConnectCryptoProvider(),
            payLogging: !AppEnvironment.current.isProduction
        )
    }
}

private extension AppMetadata {
    static let tangem = AppMetadata(
        name: "Tangem iOS",
        description: "Tangem is a card-shaped self-custodial cold hardware wallet",
        url: "https://tangem.com",
        icons: [
            "https://user-images.githubusercontent.com/24321494/124071202-72a00900-da58-11eb-935a-dcdab21de52b.png",
        ],
        redirect: .tangem
    )
}

private extension AppMetadata.Redirect {
    static let tangem: AppMetadata.Redirect = {
        do {
            return try AppMetadata.Redirect(
                native: IncomingActionConstants.universalLinkScheme,
                universal: IncomingActionConstants.tangemDomain,
                linkMode: false
            )
        } catch {
            fatalError("ReownWalletKit.AppMetadata.Redirect was malformed. A developer mistake. Please check URL strings correctness.")
        }
    }()
}
