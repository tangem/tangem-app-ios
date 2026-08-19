//
//  VisaCustomerWalletApproveTask.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk
import TangemVisa

class VisaCustomerWalletApproveTask: CardSessionRunnable {
    typealias TaskResult = CompletionResult<VisaSignedApproveResponse>
    private let targetAddress: String
    private let approveData: Data
    private let pubKeySearchUtility: VisaWalletPublicKeyUtility

    init(
        targetAddress: String,
        approveData: Data,
        isTestnet: Bool
    ) {
        self.targetAddress = targetAddress
        self.approveData = approveData
        pubKeySearchUtility = VisaWalletPublicKeyUtility(isTestnet: isTestnet)
    }

    deinit {
        VisaLogger.debug("VisaCustomerWalletApproveTask deinit")
    }

    func run(in session: CardSession, completion: @escaping TaskResult) {
        guard
            let card = session.environment.card,
            !VisaUtilities.isVisaCard(card)
        else {
            completion(.failure(.underlying(error: VisaActivationError.wrongCard)))
            return
        }

        if card.settings.isHDWalletAllowed {
            proceedApprove(card: card, in: session, completion: completion)
        } else {
            proceedApproveWithLegacyCard(card: card, in: session, completion: completion)
        }
    }
}

private extension VisaCustomerWalletApproveTask {
    func proceedApprove(card: Card, in session: CardSession, completion: @escaping TaskResult) {
        let cardDTO = CardDTO(card: card)
        let config = UserWalletConfigFactory().makeConfig(cardInfo: CardInfo(card: cardDTO, walletData: .none, associatedCardIds: []))

        guard let derivationStyle = config.derivationStyle else {
            proceedApproveWithLegacyCard(card: card, in: session, completion: completion)
            return
        }

        guard let derivationPath = VisaUtilities.visaDerivationPath(style: derivationStyle) else {
            completion(.failure(.underlying(error: VisaActivationError.missingDerivationPath)))
            return
        }

        let targetCurve = VisaUtilities.mandatoryCurve
        guard let walletPublicKey = card.wallets.first(where: { $0.curve == targetCurve })?.publicKey else {
            completion(.failure(.walletNotFound))
            return
        }

        let derivationTask = DeriveWalletPublicKeyTask(walletPublicKey: walletPublicKey, derivationPath: derivationPath)
        derivationTask.run(in: session) { result in
            switch result {
            case .success(let extendedPublicKey):
                self.processDerivedKey(
                    seedKey: walletPublicKey,
                    derivationPath: derivationPath,
                    extendedPublicKey: extendedPublicKey,
                    session: session,
                    completion: completion
                )
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    func processDerivedKey(
        seedKey: Data,
        derivationPath: DerivationPath,
        extendedPublicKey: ExtendedPublicKey,
        session: CardSession,
        completion: @escaping TaskResult
    ) {
        do {
            try pubKeySearchUtility.validateExtendedPublicKey(
                targetAddress: targetAddress,
                extendedPublicKey: extendedPublicKey,
                derivationPath: derivationPath
            )

            signApproveData(
                keyInfo: .init(
                    seedKey: seedKey,
                    keyToSignApprove: extendedPublicKey.publicKey,
                    derivationPath: derivationPath
                ),
                in: session,
                completion: completion
            )
        } catch {
            completion(.failure(.underlying(error: error)))
        }
    }

    func proceedApproveWithLegacyCard(card: Card, in session: CardSession, completion: @escaping TaskResult) {
        do {
            let publicKey = try pubKeySearchUtility.findKeyWithoutDerivation(targetAddress: targetAddress, on: card)
            signApproveData(
                keyInfo: .init(
                    seedKey: publicKey,
                    keyToSignApprove: publicKey,
                    derivationPath: nil
                ),
                in: session,
                completion: completion
            )
        } catch {
            completion(.failure(.underlying(error: error)))
        }
    }

    func signApproveData(
        keyInfo: ApproveKeyInfo,
        in session: CardSession,
        completion: @escaping TaskResult
    ) {
        let signTask = SignHashCommand(
            hash: approveData,
            walletPublicKey: keyInfo.seedKey,
            derivationPath: keyInfo.derivationPath
        )

        signTask.run(in: session) { result in
            switch result {
            case .success(let hashResponse):
                let signedResponse = VisaSignedApproveResponse(
                    keySignedApprove: keyInfo.keyToSignApprove,
                    originHash: self.approveData,
                    signature: hashResponse.signature
                )
                self.scanCard(signedResponse: signedResponse, in: session, completion: completion)
            case .failure(let sdkError):
                completion(.failure(sdkError))
            }
        }
    }

    func scanCard(signedResponse: VisaSignedApproveResponse, in session: CardSession, completion: @escaping TaskResult) {
        let scanTask = ScanTask(networkService: TangemSdkNetworkServiceFactory().makeService())

        scanTask.run(in: session) { result in
            switch result {
            case .success:
                completion(.success(signedResponse))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
}

private extension VisaCustomerWalletApproveTask {
    struct ApproveKeyInfo {
        let seedKey: Data
        let keyToSignApprove: Data
        let derivationPath: DerivationPath?
    }
}
