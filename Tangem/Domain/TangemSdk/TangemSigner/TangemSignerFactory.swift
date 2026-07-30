//
//  TangemSignerFactory.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import BlockchainSdk
import TangemSdk

/// Mints a fresh signer from the live `UserWalletModel` on every call.
/// Long-lived holders must retain this factory instead of a `TangemSigner`,
/// otherwise the signer freezes the card state and SDK configuration it was created with.
final class TangemSignerFactory {
    private weak var userWalletModel: (any UserWalletModel)?

    init(userWalletModel: (any UserWalletModel)? = nil) {
        self.userWalletModel = userWalletModel
    }

    func configure(with userWalletModel: any UserWalletModel) {
        self.userWalletModel = userWalletModel
    }

    func makeSigner() -> any TangemSigner {
        userWalletModel?.signer ?? DeallocatedUserWalletModelSigner()
    }
}

// MARK: - Fallback stub

private struct DeallocatedUserWalletModelSigner: TangemSigner {
    var hasNFCInteraction: Bool { false }
    var latestSignerType: TangemSignerType? { nil }

    func sign(dataToSign: [SignData], walletPublicKey: Wallet.PublicKey) -> AnyPublisher<[SignatureInfo], Error> {
        stub()
    }

    func sign(hash: Data, walletPublicKey: Wallet.PublicKey) -> AnyPublisher<SignatureInfo, Error> {
        stub()
    }

    func sign(hashes: [Data], walletPublicKey: Wallet.PublicKey) -> AnyPublisher<[SignatureInfo], Error> {
        stub()
    }

    private func stub<T>(for function: StaticString = #function) -> AnyPublisher<T, Error> {
        .anyFail(error: "UserWalletModel is deallocated, signing using '\(function)' is unavailable")
    }
}
