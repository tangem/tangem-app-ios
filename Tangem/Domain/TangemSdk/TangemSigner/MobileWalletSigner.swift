//
//  MobileWalletSigner.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemHotSdk
import BlockchainSdk
import Combine
import TangemSdk
import TangemFoundation

final class MobileWalletSigner {
    let userWalletConfig: UserWalletConfig
    let hotSdk = CommonHotSdk()

    init(userWalletConfig: UserWalletConfig) {
        self.userWalletConfig = userWalletConfig
    }
}

extension MobileWalletSigner: TangemSigner {
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

                return try await unlock(userWalletId: userWalletId)
            }
            .eraseToAnyPublisher()

        let signedDataPublisher = mobileWalletContextPublisher
            .tryMap { [hotSdk] context in
                try hotSdk.sign(
                    dataToSign: dataToSign,
                    seedKey: walletPublicKey.seedKey,
                    context: context
                )
            }

        return signedDataPublisher
            .map { signedHashesInfo in
                return dataToSign
                    .compactMap { dataToSign -> [SignatureInfo]? in
                        guard let signedHashes = signedHashesInfo[dataToSign.publicKey] else { return nil }
                        return zip(signedHashes, dataToSign.hashes).map { signedHash, hashToSign in
                            return SignatureInfo(signature: signedHash, publicKey: dataToSign.publicKey, hash: hashToSign)
                        }
                    }
                    .flatMap { $0 }
            }
            .eraseToAnyPublisher()
    }
}

private extension MobileWalletSigner {
    func unlock(userWalletId: UserWalletId) async throws -> MobileWalletContext {
        let authUtil = HotAuthUtil(userWalletId: userWalletId, config: userWalletConfig)
        let unlockResult = try await authUtil.unlock()

        return try await handleUnlockResult(unlockResult, userWalletId: userWalletId)
    }

    func handleUnlockResult(
        _ result: HotAuthUtil.Result,
        userWalletId: UserWalletId
    ) async throws -> MobileWalletContext {
        switch result {
        case .successful(let context):
            return context
        case .canceled, .userWalletNeedsToDelete:
            throw CancellationError()
        }
    }
}
