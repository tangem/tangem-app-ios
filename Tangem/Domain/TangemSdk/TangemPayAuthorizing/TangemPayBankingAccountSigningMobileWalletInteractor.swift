//
//  TangemPayBankingAccountSigningMobileWalletInteractor.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation
import TangemSdk
import BlockchainSdk
import TangemMobileWalletSdk
import TangemPay

final class TangemPayBankingAccountSigningMobileWalletInteractor: TangemPayBankingAccountAddressSigning {
    private let userWalletId: UserWalletId
    private let userWalletConfig: UserWalletConfig
    private let mobileWalletSdk = CommonMobileWalletSdk()

    init(userWalletId: UserWalletId, userWalletConfig: UserWalletConfig) {
        self.userWalletId = userWalletId
        self.userWalletConfig = userWalletConfig
    }

    func signDepositAddress() async throws(TangemPayBankingAccountSigningError) -> TangemPayBankingAccountSigningResponse {
        var derivationResult: DerivationResult = [:]

        do {
            let context = try await MobileAuthUtil(
                userWalletId: userWalletId,
                config: userWalletConfig,
                biometricsProvider: CommonUserWalletBiometricsProvider()
            )
            .unlockedContext()
            let mobileWallet = try mobileWalletSdk.deriveMasterKeys(context: context)

            let customerWalletPath = TangemPayUtilities.derivationPath
            let depositPath = TangemPayUtilities.bankingAccountDerivationPath

            guard let seedKey = mobileWallet.wallets.first(where: { $0.curve == TangemPayUtilities.mandatoryCurve })?.publicKey else {
                throw Error.derivedKeyNotFound
            }

            let rawResult = try mobileWalletSdk.deriveKeys(context: context, derivationPaths: [seedKey: [customerWalletPath, depositPath]])

            derivationResult = rawResult.reduce(into: [:]) { partialResult, keyInfo in
                partialResult[keyInfo.key] = .init(keys: keyInfo.value.derivedKeys)
            }

            guard
                let customerWalletKey = derivationResult[seedKey]?[customerWalletPath],
                let depositKey = derivationResult[seedKey]?[depositPath]
            else {
                throw Error.derivedKeyNotFound
            }

            let customerWalletPublicKey = Wallet.PublicKey(
                seedKey: seedKey,
                derivationType: .plain(.init(path: customerWalletPath, extendedPublicKey: customerWalletKey))
            )
            let depositPublicKey = Wallet.PublicKey(
                seedKey: seedKey,
                derivationType: .plain(.init(path: depositPath, extendedPublicKey: depositKey))
            )

            let depositAddress = try TangemPayUtilities.makeAddress(using: depositPublicKey)
            let signRequest = try TangemPayUtilities.prepareBankingAccountDepositAddressForSign(depositAddress: depositAddress)

            let dataToSign = SignData(
                derivationPath: customerWalletPublicKey.derivationPath,
                hashes: [signRequest.hash],
                publicKey: customerWalletPublicKey.blockchainKey
            )

            let signResponse = try mobileWalletSdk.sign(
                dataToSign: [dataToSign],
                seedKey: customerWalletPublicKey.seedKey,
                context: context
            )

            guard let signature = signResponse.first?.signature else {
                throw Error.signatureNotFound
            }

            let unmarshalledSignature = try Secp256k1Signature(with: signature).unmarshal(
                with: customerWalletPublicKey.blockchainKey,
                hash: signRequest.hash
            )

            return TangemPayBankingAccountSigningResponse(
                depositAddress: depositAddress,
                signature: unmarshalledSignature.data.hexString.lowercased(),
                derivationResult: derivationResult
            )
        } catch {
            throw TangemPayBankingAccountSigningError(underlyingError: error, derivationResult: derivationResult)
        }
    }
}

extension TangemPayBankingAccountSigningMobileWalletInteractor {
    enum Error: Swift.Error {
        case derivedKeyNotFound
        case signatureNotFound
    }
}
