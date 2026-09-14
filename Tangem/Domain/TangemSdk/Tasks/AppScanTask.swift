//
//  AppScanTask.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk
import TangemFoundation
import TangemVisa

final class AppScanTask: CardSessionRunnable {
    @Injected(\.visaRefreshTokenRepository) private var visaRefreshTokenRepository: VisaRefreshTokenRepository

    var preflightReadMode: PreflightReadMode {
        var options: PreflightReadMode.Options = [.readMasterSecret, .verifyBackup]

        if shouldCheckAccessCode {
            options.insert(.accessCodeCheck)
        }

        return .fullCardRead(options: options)
    }

    let shouldAskForAccessCode: Bool

    private let shouldCheckAccessCode: Bool
    private let userWalletRegistrar = CardUserWalletRegistrar()
    private var walletData: DefaultWalletData = .none
    private var primaryCard: PrimaryCard?
    private var linkingCommand: StartPrimaryCardLinkingCommand?

    init(
        shouldAskForAccessCode: Bool = false,
        shouldCheckAccessCode: Bool = false
    ) {
        self.shouldAskForAccessCode = shouldAskForAccessCode
        self.shouldCheckAccessCode = shouldCheckAccessCode
    }

    deinit {
        AppLogger.debug("AppScanTask deinit")
    }

    func prepare(_ session: CardSession, completion: @escaping CompletionResult<Void>) {
        // Obtaining the nonce before the NFC session opens, so the NFC session remains responsive
        userWalletRegistrar.obtainNonce {
            completion(.success(()))
        }
    }

    public func run(in session: CardSession, completion: @escaping CompletionResult<AppScanTaskResponse>) {
        guard let card = session.environment.card else {
            completion(.failure(.missingPreflightRead))
            return
        }

        TangemSdkAnalyticsLogger().logHealthIfNeeded(card)

        if VisaUtilities.isVisaCard(card) {
            guard FeatureProvider.isAvailable(.visa) else {
                completion(.failure(.notSupportedFirmwareVersion))
                return
            }

            readVisaCard(session, completion)
            return
        }

        // tmp disable reading cards with imported wallets
        if card.firmwareVersion < .ed25519Slip0010Available,
           card.wallets.contains(where: { $0.isImported == true }) {
            completion(.failure(.wrongCardType(nil)))
            return
        }

        if let legacyWalletData = session.environment.walletData,
           legacyWalletData.blockchain != "ANY" {
            walletData = .legacy(legacyWalletData)
        }

        readExtra(session: session, completion: completion)
    }

    private func readExtra(session: CardSession, completion: @escaping CompletionResult<AppScanTaskResponse>) {
        guard let card = session.environment.card else {
            completion(.failure(.missingPreflightRead))
            return
        }

        if TwinCardsUtils.isTwinCard(card) {
            readTwin(card, session: session, completion: completion)
            return
        }

        if card.firmwareVersion.doubleValue >= 4.39 {
            if card.settings.maxWalletsCount == 1 {
                readFile(card, session: session, completion: completion)
            } else {
                readPrimaryIfNeeded(card, session, completion)
            }

            return
        }

        registerUserWalletIfNeeded(session, completion)
    }

    private func readPrimaryIfNeeded(_ card: Card, _ session: CardSession, _ completion: @escaping CompletionResult<AppScanTaskResponse>) {
        let isWalletInOnboarding = AppSettings.shared.cardsStartedActivation.contains(card.cardId)

        let masterSecretInitialized = card.firmwareVersion >= .v8 ? card.masterSecret != nil : true
        let shouldReadPrimaryCard = card.settings.isBackupAllowed && card.backupStatus == .noBackup && masterSecretInitialized

        if isWalletInOnboarding, shouldReadPrimaryCard {
            readPrimaryCard(session, completion)
            return
        } else {
            registerUserWalletIfNeeded(session, completion)
            return
        }
    }

    private func readFile(_ card: Card, session: CardSession, completion: @escaping CompletionResult<AppScanTaskResponse>) {
        func exit() {
            readPrimaryIfNeeded(card, session, completion)
        }

        let readFileCommand = ReadFilesTask(fileName: "blockchainInfo", walletPublicKey: nil)
        readFileCommand.run(in: session) { result in
            switch result {
            case .success(let response):
                guard let file = response.first,
                      let tlv = Tlv.deserialize(file.data),
                      let fileSignature = file.signature,
                      let fileCounter = file.counter,
                      let walletData = try? WalletDataDeserializer().deserialize(decoder: TlvDecoder(tlv: tlv)) else {
                    exit()
                    return
                }

                let dataToVerify = Data(hexString: card.cardId) + file.data + fileCounter.bytes4
                let isVerified: Bool = (try? CryptoUtils.verify(
                    curve: .secp256k1,
                    publicKey: card.issuer.publicKey,
                    message: dataToVerify,
                    signature: fileSignature
                )) ?? false

                guard isVerified else {
                    exit()
                    return
                }

                if walletData.blockchain != "ANY" {
                    self.walletData = .file(walletData)
                }

                exit()
            case .failure(let error):
                switch error {
                case .fileNotFound, .insNotSupported:
                    exit()
                default:
                    completion(.failure(error))
                }
            }
        }
    }

    private func readTwin(_ card: Card, session: CardSession, completion: @escaping CompletionResult<AppScanTaskResponse>) {
        let readIssuerDataCommand = ReadIssuerDataCommand()
        readIssuerDataCommand.run(in: session) { result in
            switch result {
            case .success(let response):
                if let walletData = session.environment.walletData {
                    let twinData = self.decodeTwinFile(from: card, twinIssuerData: response.issuerData)
                    self.walletData = .twin(walletData, twinData)
                }

                self.registerUserWalletIfNeeded(session, completion)
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    private func decodeTwinFile(from card: Card, twinIssuerData: Data) -> TwinData {
        var pairPublicKey: Data?

        if let walletPubKey = card.wallets.first?.publicKey, twinIssuerData.count == 129 {
            let pairPubKey = twinIssuerData[0 ..< 65]
            let signature = twinIssuerData[65 ..< twinIssuerData.count]
            if (try? Secp256k1Signature(with: signature).verify(with: walletPubKey, message: pairPubKey)) ?? false {
                pairPublicKey = pairPubKey
            }
        }

        return TwinData(
            series: TwinCardsUtils.series(for: card)!,
            pairPublicKey: pairPublicKey
        )
    }

    private func readPrimaryCard(_ session: CardSession, _ completion: @escaping CompletionResult<AppScanTaskResponse>) {
        linkingCommand = StartPrimaryCardLinkingCommand()
        linkingCommand!.run(in: session) { result in
            switch result {
            case .success(let primaryCard):
                self.primaryCard = primaryCard
                self.registerUserWalletIfNeeded(session, completion)
            case .failure: // ignore any error
                self.registerUserWalletIfNeeded(session, completion)
            }
        }
    }

    private func readVisaCard(_ session: CardSession, _ completion: @escaping CompletionResult<AppScanTaskResponse>) {
        let handler = VisaCardScanHandlerBuilder()
            .build(refreshTokenRepository: visaRefreshTokenRepository)

        handler.run(in: session) { result in
            switch result {
            case .success(let success):
                self.walletData = .visa(success)
                self.registerUserWalletIfNeeded(session, completion)
            case .failure(let error):
                completion(.failure(error))
            }

            withExtendedLifetime(handler) {}
        }
    }

    private func registerUserWalletIfNeeded(_ session: CardSession, _ completion: @escaping CompletionResult<AppScanTaskResponse>) {
        userWalletRegistrar.registerIfNeeded(in: session) {
            self.runScanTask(session, completion)
        }
    }

    private func runScanTask(_ session: CardSession, _ completion: @escaping CompletionResult<AppScanTaskResponse>) {
        let scanTask = ScanTask(networkService: TangemSdkNetworkServiceFactory().makeService())
        scanTask.run(in: session) { result in
            switch result {
            case .success:
                self.complete(session, completion)
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    private func complete(_ session: CardSession, _ completion: @escaping CompletionResult<AppScanTaskResponse>) {
        guard let card = session.environment.card else {
            completion(.failure(.missingPreflightRead))
            return
        }

        let response = AppScanTaskResponse(
            card: card,
            walletData: walletData,
            primaryCard: primaryCard
        )

        completion(.success(response))
    }
}
