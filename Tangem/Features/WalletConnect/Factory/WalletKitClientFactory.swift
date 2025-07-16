//
//  WalletKitClientFactory.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import ReownWalletKit
import enum TangemFoundation.AppEnvironment

enum WalletKitClientFactory {
    @Injected(\.keysManager) private static var keysManager: KeysManager

    static func make() -> ReownWalletKit.WalletKitClient {
        configureNetworking()
        configureWalletKit()

        return WalletKit.instance
    }

    private static func configureNetworking() {
        Networking.configure(
            groupIdentifier: AppEnvironment.current.suiteName,
            projectId: keysManager.walletConnectProjectId,
            socketFactory: WalletConnectV2DefaultSocketFactory(),
            socketConnectionType: .automatic
        )
    }

    private static func configureWalletKit() {
        WalletKit.configure(metadata: .tangem, crypto: WalletConnectCryptoProvider())
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
