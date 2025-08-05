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
    let hotWalletInfo: HotWalletInfo

    init(hotWalletInfo: HotWalletInfo) {
        self.hotWalletInfo = hotWalletInfo
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
        do {
            guard let userWalletIdSeed = hotWalletInfo.keys.first?.publicKey else {
                return Fail(error: MobileWalletError.seedKeyNotFound).eraseToAnyPublisher()
            }

            let sdk = CommonHotSdk()

            let context = try sdk.validate(auth: .none, for: UserWalletId(with: userWalletIdSeed))

            // [REDACTED_TODO_COMMENT]
            let signedHashesInfo = try sdk.sign(
                dataToSign: dataToSign,
                seedKey: walletPublicKey.seedKey,
                context: context
            )

            let result = dataToSign
                .compactMap { dataToSign -> [SignatureInfo]? in
                    guard let signedHashes = signedHashesInfo[dataToSign.publicKey] else { return nil }
                    return zip(signedHashes, dataToSign.hashes).map { signedHash, hashToSign in
                        return SignatureInfo(signature: signedHash, publicKey: dataToSign.publicKey, hash: hashToSign)
                    }
                }
                .flatMap { $0 }

            return .justWithError(output: result)
        } catch {
            return Fail(error: error).eraseToAnyPublisher()
        }
    }
}
