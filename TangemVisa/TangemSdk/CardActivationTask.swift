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

protocol CardActivationTaskOrderProvider: AnyObject {
    func getOrderForSignedAuthorizationChallenge(
        signedAuthorizationChallenge: AttestCardKeyResponse,
        completion: @escaping (Result<VisaCardAcceptanceOrderInfo, Error>) -> Void
    )
    func getActivationOrder(completion: @escaping (Result<VisaCardAcceptanceOrderInfo, Error>) -> Void)
}

final class CardActivationTask: CardSessionRunnable {
    typealias CompletionHandler = CompletionResult<CardActivationResponse>

    private weak var orderProvider: CardActivationTaskOrderProvider?
    private var otpRepository: VisaOTPRepository
    private let logger = InternalLogger(tag: .cardActivationTask)

    private let selectedAccessCode: String
    private let activationInput: VisaCardActivationInput
    private let challengeToSign: String?

    private var taskCancellationError: TangemSdkError?

    private var orderPublisher = CurrentValueSubject<VisaCardAcceptanceOrderInfo?, Error>(nil)
    private var orderSubscription: AnyCancellable?

    init(
        selectedAccessCode: String,
        activationInput: VisaCardActivationInput,
        challengeToSign: String?,
        delegate: CardActivationTaskOrderProvider,
        otpRepository: VisaOTPRepository
    ) {
        self.selectedAccessCode = selectedAccessCode
        self.activationInput = activationInput
        self.challengeToSign = challengeToSign
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

        if let challengeToSign {
            let challengeDataToSign = Data(hexString: challengeToSign)
            signAuthorizationChallenge(challengeToSign: challengeDataToSign, in: session, completion: completion)
        } else {
            getActivationOrder(in: session, completion: completion)
        }
    }
}

// MARK: - Card Activation Flow

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

        let utils = VisaUtilities(isTestnet: false)
        if card.wallets.contains(where: { $0.curve == utils.mandatoryCurve }) {
            createOTP(in: session, completion: completion)
            return
        }

        let createWallet = CreateWalletTask(curve: utils.mandatoryCurve)
        createWallet.run(in: session) { result in
            switch result {
            case .success:
                self.createOTP(in: session, completion: completion)
            case .failure(let error):
                completion(.failure(error))
            }
        }
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
            waitForOrder(rootOTP: otp, in: session, completion: completion)
            return
        }

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
                self.signOrder(
                    orderToSign: activationOrder,
                    in: session,
                    completion: completion
                )
                self.orderSubscription = nil
            })
    }
}

// MARK: - Order signing

private extension CardActivationTask {
    func signOrder(orderToSign: VisaCardAcceptanceOrderInfo, in session: CardSession, completion: @escaping CompletionHandler) {
        let signOrderTask = SignActivationOrderTask(orderToSign: orderToSign)

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

        let cardActivationResponse = CardActivationResponse(
            signedActivationOrder: signedOrder,
            rootOTP: otp.rootOTP,
            rootOTPCounter: otp.rootOTPCounter
        )
        setupAccessCode(signResponse: cardActivationResponse, in: session, completion: completion)
    }

    func setupAccessCode(
        signResponse: CardActivationResponse,
        in session: CardSession,
        completion: @escaping CompletionHandler
    ) {
        guard let card = session.environment.card else {
            completion(.failure(.missingPreflightRead))
            return
        }

        if card.isAccessCodeSet {
            completion(.success(signResponse))
            return
        }

        let setAccessCodeCommand = SetUserCodeCommand(accessCode: selectedAccessCode)
        setAccessCodeCommand.run(in: session) { result in
            switch result {
            case .success:
                completion(.success(signResponse))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
}

// MARK: - Order loading related

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

        orderProvider.getOrderForSignedAuthorizationChallenge(signedAuthorizationChallenge: signResponse) { [weak self] result in
            self?.processActivationOrder(result)
        }
        createWallet(in: session, completion: completion)
    }

    func getActivationOrder(in session: CardSession, completion: @escaping CompletionHandler) {
        guard let orderProvider else {
            let missingDelegateError = VisaActivationError.taskMissingDelegate
            taskCancellationError = .underlying(error: missingDelegateError)
            completion(.failure(.underlying(error: missingDelegateError)))
            return
        }

        orderProvider.getActivationOrder { [weak self] result in
            self?.processActivationOrder(result)
        }
        createWallet(in: session, completion: completion)
    }

    func processActivationOrder(_ result: Result<VisaCardAcceptanceOrderInfo, Error>) {
        switch result {
        case .success(let activationOrder):
            orderPublisher.send(activationOrder)
        case .failure(let error):
            taskCancellationError = .underlying(error: error)
            orderPublisher.send(completion: .failure(error))
        }
    }
}
