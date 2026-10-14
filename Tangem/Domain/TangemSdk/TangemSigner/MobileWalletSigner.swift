//
//  MobileWalletSigner.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemMobileWalletSdk
import BlockchainSdk
import Combine
import TangemSdk
import TangemFoundation

final class MobileWalletSigner {
    let userWalletConfig: UserWalletConfig
    let mobileWalletSdk = CommonMobileWalletSdk()

    init(userWalletConfig: UserWalletConfig) {
        self.userWalletConfig = userWalletConfig
    }
}

extension MobileWalletSigner: TangemSigner {
    var hasNFCInteraction: Bool { false }

    var latestSignerType: TangemSignerType? {
        .mobileWallet
    }

    func sign(hashes: [Data], walletPublicKey: Wallet.PublicKey) -> AnyPublisher<[SignatureInfo], any Error> {
        let dataToSign = SignData(
            derivationPath: walletPublicKey.derivationPath,
            hashes: hashes,
            publicKey: walletPublicKey.blockchainKey
        )
        return sign(dataToSign: [dataToSign], walletPublicKey: walletPublicKey)
    }

    func sign(hash: Data, walletPublicKey: Wallet.PublicKey) -> AnyPublisher<SignatureInfo, Error> {
        sign(hashes: [hash], walletPublicKey: walletPublicKey)
            .map { $0[0] }
            .eraseToAnyPublisher()
    }

    func sign(
        dataToSign: [SignData],
        walletPublicKey: Wallet.PublicKey
    ) -> AnyPublisher<[SignatureInfo], any Error> {
        guard let userWalletIdSeed = userWalletConfig.userWalletIdSeed else {
            return Fail(error: MobileWalletError.seedKeyNotFound).eraseToAnyPublisher()
        }

        let userWalletId = UserWalletId(with: userWalletIdSeed)

        let userWalletIdPublisher: AnyPublisher<UserWalletId, Error> = .justWithError(output: userWalletId)

        let mobileWalletContextPublisher: AnyPublisher<MobileWalletContext, Error> = userWalletIdPublisher
            .asyncTryMap { [weak self] userWalletId in
                guard let self else {
                    throw CancellationError()
                }

                return try await MobileAuthUtil(
                    userWalletId: userWalletId,
                    config: userWalletConfig,
                    biometricsProvider: CommonUserWalletBiometricsProvider()
                )
                .unlockedContext()
            }
            .eraseToAnyPublisher()

        let signedDataPublisher = mobileWalletContextPublisher
            .tryMap { [mobileWalletSdk] context in
                try mobileWalletSdk.sign(
                    dataToSign: dataToSign,
                    seedKey: walletPublicKey.seedKey,
                    context: context
                )
            }

        return signedDataPublisher
            .map { signatures in
                signatures.map { SignatureInfo(signature: $0.signature, publicKey: $0.publicKey, hash: $0.hash) }
            }
            .eraseToAnyPublisher()
    }
}
