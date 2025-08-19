//
//  CardActivationTask.swift
//  TangemVisa
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemSdk

public struct CardActivationResponse {
    public let signedActivationOrder: SignedActivationOrder
    public let rootOTP: Data
    public let rootOTPCounter: Int
}

protocol CardActivationTaskDelegate: AnyObject {
    func processAuthorizationChallenge(
        signedAuthorizationChallenge: AttestCardKeyResponse,
        completion: @escaping (Result<Void, Error>) -> Void
    )
    func getActivationOrder(walletAddress: String, completion: @escaping (Result<VisaCardAcceptanceOrderInfo, Error>) -> Void)
}

/// Task for second tap during activation process. During this task app must:
///  - 1 (optional). Sign loaded authorization challenge, resulting signature will be used to load authorization tokens.
///             This step is skipped for cases when authorization tokens already acquired during first scan
///  - 2. Create Wallet on secp256k1 curve
///  - 3. Create OTP
///  - 4. Sign acceptance message with created wallet
///  During 2 and 3 steps executes request to BFF for loading acceptance message
///  Each step of interaction with card can be skipped if card already executed it.
///  OTP must be stored locally, so if user start activation process from the begining OTP must be generated again
final class CardActivationTask: CardSessionRunnable {
    typealias CompletionHandler = CompletionResult<CardActivationResponse>

    private weak var orderProvider: CardActivationTaskDelegate?
    private var otpRepository: VisaOTPRepository

    private let accessCodeSetupType: AccessCodeSetupType
    private let activationInput: VisaCardActivationInput
    private let isTestnet: Bool
    private let authorizationChallengeToSign: String?

    private var taskCancellationError: TangemSdkError?

    private var orderPublisher = CurrentValueSubject<VisaCardAcceptanceOrderInfo?, Error>(nil)
    private var isAuthorizedInBFFPublisher: CurrentValueSubject<Bool, Error>
    private var orderSubscription: AnyCancellable?
    private var bffAuthorizationSubscription: AnyCancellable?

    init(
        accessCodeSetupType: AccessCodeSetupType,
        activationInput: VisaCardActivationInput,
        isTestnet: Bool,
        authorizationChallengeToSign: String?,
        delegate: CardActivationTaskDelegate,
        otpRepository: VisaOTPRepository
    ) {
        self.accessCodeSetupType = accessCodeSetupType
        self.activationInput = activationInput
        self.isTestnet = isTestnet
        self.authorizationChallengeToSign = authorizationChallengeToSign
        isAuthorizedInBFFPublisher = .init(authorizationChallengeToSign == nil)
        orderPublisher.send(nil)

        orderProvider = delegate
        self.otpRepository = otpRepository
    }

    func run(in session: CardSession, completion: @escaping CompletionHandler) {
        guard let card = session.environment.card else {
            completion(.failure(TangemSdkError.missingPreflightRead))
            return
        }

        guard card.cardId.caseInsensitiveCompare(activationInput.cardId) == .orderedSame else {
            completion(.failure(.underlying(error: VisaActivationError.wrongCard)))
            return
        }

        if let authorizationChallengeToSign {
            let challengeDataToSign = Data(hexString: authorizationChallengeToSign)
            VisaLogger.info("Contains challenge to sign. Start authorization flow")
            signAuthorizationChallenge(challengeToSign: challengeDataToSign, in: session, completion: completion)
        } else {
            VisaLogger.info("No authorization challenge, attempting to load activation order")
            createWallet(in: session, completion: completion)
        }
    }
}

// MARK: - Card interactions

private extension CardActivationTask {
    func signAuthorizationChallenge(challengeToSign: Data, in session: CardSession, completion: @escaping CompletionHandler) {
        let attestationCommand = AttestCardKeyCommand(challenge: challengeToSign)
        attestationCommand.run(in: session) { result in
            switch result {
            case .success(let response):
                self.processSignedAuthorizationChallenge(signResponse: response, in: session, completion: completion)
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    func createWallet(in session: CardSession, completion: @escaping CompletionHandler) {
        if let taskCancellationError {
            completion(.failure(taskCancellationError))
            return
        }

        guard let card = session.environment.card else {
            completion(.failure(.missingPreflightRead))
            return
        }

        if card.wallets.contains(where: { $0.curve == VisaUtilities.mandatoryCurve }) {
            VisaLogger.info("Wallet already created. Moving to OTP creation")
            deriveKey(in: session, completion: completion)
            return
        }

        VisaLogger.info("Wallet not created. Creating wallet")
        let createWallet = CreateWalletTask(curve: VisaUtilities.mandatoryCurve)
        createWallet.run(in: session) { result in
            switch result {
            case .success:
                self.deriveKey(in: session, completion: completion)
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    func deriveKey(in session: CardSession, completion: @escaping CompletionHandler) {
        guard
            let wallet = session.environment.card?.wallets.first(where: { $0.curve == VisaUtilities.mandatoryCurve })
        else {
            completion(.failure(.underlying(error: VisaActivationError.missingWallet)))
            return
        }

        processDerivedKey(wallet: wallet, in: session, completion: completion)
    }

    func createOTP(in session: CardSession, completion: @escaping CompletionHandler) {
        if let taskCancellationError {
            completion(.failure(taskCancellationError))
            return
        }

        guard let card = session.environment.card else {
            completion(.failure(.missingPreflightRead))
            return
        }

        if let otp = otpRepository.getOTP(cardId: card.cardId) {
            VisaLogger.info("OTP already created. Moving to awaiting activcation order")
            waitForOrder(rootOTP: otp, in: session, completion: completion)
            return
        }

        VisaLogger.info("OTP not created. Creating OTP")
        let otpCommand = GenerateOTPCommand()
        otpCommand.run(in: session) { result in
            switch result {
            case .success(let otpResponse):
                self.otpRepository.saveOTP(otpResponse, cardId: card.cardId)
                self.waitForOrder(rootOTP: otpResponse, in: session, completion: completion)
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    // MARK: Setup Access code

    func setupAccessCode(
        signResponse: CardActivationResponse,
        in session: CardSession,
        completion: @escaping CompletionHandler
    ) {
        guard let card = session.environment.card else {
            completion(.failure(.missingPreflightRead))
            return
        }

        switch accessCodeSetupType {
        case .newAccessCode(let accessCode):
            VisaLogger.info("Access code not set. Starting commnand")
            let setAccessCodeCommand = SetUserCodeCommand(accessCode: accessCode)
            setAccessCodeCommand.run(in: session) { result in
                switch result {
                case .success:
                    VisaLogger.info("Access code setup finished")
                    completion(.success(signResponse))
                case .failure(let error):
                    completion(.failure(error))
                }
            }
        case .alreadySet:
            guard card.isAccessCodeSet else {
                VisaLogger.error("Access code setup must be set, but on card it didn't", error: VisaActivationError.missingAccessCode)
                completion(.failure(.underlying(error: VisaActivationError.missingAccessCode)))
                return
            }

            VisaLogger.info("Access code already set. Finishing activation task")
            completion(.success(signResponse))
        }
    }
}

// MARK: - Authorization

private extension CardActivationTask {
    func processSignedAuthorizationChallenge(
        signResponse: AttestCardKeyResponse,
        in session: CardSession,
        completion: @escaping CompletionHandler
    ) {
        guard let orderProvider else {
            let missingDelegateError = VisaActivationError.taskMissingDelegate
            taskCancellationError = .underlying(error: missingDelegateError)
            completion(.failure(.underlying(error: missingDelegateError)))
            return
        }

        orderProvider.processAuthorizationChallenge(signedAuthorizationChallenge: signResponse) { [weak self] result in
            switch result {
            case .success:
                self?.isAuthorizedInBFFPublisher.send(true)
            case .failure(let error):
                self?.taskCancellationError = .underlying(error: error)
                self?.isAuthorizedInBFFPublisher.send(completion: .failure(error))
            }
        }

        VisaLogger.info("Processing signed authorization challenge finished. Starting create wallet process")
        createWallet(in: session, completion: completion)
    }

    func awaitBFFAuthorization(walletAddress: String) {
        bffAuthorizationSubscription = isAuthorizedInBFFPublisher
            .filter { $0 }
            .sink { [weak self] completion in
                if case .failure(let error) = completion {
                    self?.taskCancellationError = .underlying(error: error)
                }
            } receiveValue: { [weak self] _ in
                self?.getActivationOrder(walletAddress: walletAddress)
            }
    }
}

// MARK: - Order related

private extension CardActivationTask {
    func signOrder(orderToSign: VisaCardAcceptanceOrderInfo, in session: CardSession, completion: @escaping CompletionHandler) {
        let signOrderTask = SignActivationOrderTask(orderToSign: orderToSign)

        VisaLogger.info("Starting activation order sign task")
        signOrderTask.run(in: session, completion: { result in
            switch result {
            case .success(let signedOrder):
                self.handleSignedActivationOrder(signedOrder, in: session, completion: completion)
            case .failure(let error):
                completion(.failure(error))
            }

            withExtendedLifetime(signOrderTask) {}
        })
    }

    func handleSignedActivationOrder(
        _ signedOrder: SignedActivationOrder,
        in session: CardSession,
        completion: @escaping CompletionHandler
    ) {
        guard let card = session.environment.card else {
            completion(.failure(.missingPreflightRead))
            return
        }

        guard let otp = otpRepository.getOTP(cardId: card.cardId) else {
            completion(.failure(.underlying(error: VisaActivationError.missingRootOTP)))
            return
        }

        VisaLogger.info("Received signed order and OTP, moving to Access Code setup")
        let cardActivationResponse = CardActivationResponse(
            signedActivationOrder: signedOrder,
            rootOTP: otp.rootOTP,
            rootOTPCounter: otp.rootOTPCounter
        )
        setupAccessCode(signResponse: cardActivationResponse, in: session, completion: completion)
    }
}

// MARK: - Order loading related

private extension CardActivationTask {
    func processDerivedKey(
        wallet: Card.Wallet,
        in session: CardSession,
        completion: @escaping CompletionHandler
    ) {
        do {
            let address = try VisaUtilities.makeAddress(walletPublicKey: wallet.publicKey, isTestnet: isTestnet)
            awaitBFFAuthorization(walletAddress: address.value)
            createOTP(in: session, completion: completion)
        } catch {
            completion(.failure(.underlying(error: error)))
            return
        }
    }

    func waitForOrder(rootOTP: GenerateOTPResponse, in session: CardSession, completion: @escaping CompletionHandler) {
        if let taskCancellationError {
            completion(.failure(taskCancellationError))
            return
        }

        orderSubscription = orderPublisher
            .compactMap { $0 }
            .sink(receiveCompletion: { [weak self] orderPublisherCompletion in
                if case .failure(let error) = orderPublisherCompletion {
                    completion(.failure(.underlying(error: error)))
                }

                self?.orderSubscription = nil
            }, receiveValue: { activationOrder in
                VisaLogger.info("Activation order received. Continue with order signing")
                self.signOrder(
                    orderToSign: activationOrder,
                    in: session,
                    completion: completion
                )
                self.orderSubscription = nil
            })
    }

    func getActivationOrder(walletAddress: String) {
        guard
            taskCancellationError == nil,
            let orderProvider
        else {
            let missingDelegateError = VisaActivationError.taskMissingDelegate
            taskCancellationError = .underlying(error: missingDelegateError)
            return
        }

        orderProvider.getActivationOrder(walletAddress: walletAddress) { [weak self] result in
            switch result {
            case .success(let activationOrder):
                self?.orderPublisher.send(activationOrder)
            case .failure(let error):
                self?.taskCancellationError = .underlying(error: error)
                self?.orderPublisher.send(completion: .failure(error))
            }
        }
    }
}

extension CardActivationTask {
    enum AccessCodeSetupType {
        case newAccessCode(accessCode: String)
        case alreadySet
    }
}
