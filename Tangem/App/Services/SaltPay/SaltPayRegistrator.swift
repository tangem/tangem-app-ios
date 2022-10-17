//
//  SaltPayRegistrator.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk
import BlockchainSdk
import web3swift
import Combine

class SaltPayRegistrator {
    @Published public private(set) var state: State = .needPin
    @Published public private(set) var error: AlertBinder? = nil
    @Published public private(set) var isBusy: Bool = false

    var kycURL: URL {
        let kycProvider = keysManager.saltPay.kycProvider

        var urlComponents = URLComponents(string: kycProvider.baseUrl)!

        var queryItems = [URLQueryItem]()
        queryItems.append(.init(name: kycProvider.externalIdParameterKey, value: kycRefId))
        queryItems.append(.init(name: kycProvider.sidParameterKey, value: kycProvider.sidValue))

        urlComponents.queryItems = queryItems
        return urlComponents.url!
    }

    var kycDoneURL: String {
        "https://success.tangem.com"
    }

    @Injected(\.tangemSdkProvider) private var tangemSdkProvider: TangemSdkProviding
    @Injected(\.keysManager) private var keysManager: KeysManager

    private let api: PaymentologyApiService = CommonPaymentologyApiService()
    private let gnosis: GnosisRegistrator
    private let cardId: String
    private let cardPublicKey: Data
    private let walletPublicKey: Data
    private var bag: Set<AnyCancellable> = .init()
    private var pin: String? = nil
    private var registrationTask: RegistrationTask? = nil
    private var accessCode: String? = nil // "111111" //[REDACTED_TODO_COMMENT]

    private let approvalValue: Decimal = .greatestFiniteMagnitude
    private let spendLimitValue: Decimal = 100

    private var kycRefId: String {
        UserWalletId(with: walletPublicKey).stringValue
    }

    init(cardId: String, cardPublicKey: Data, walletPublicKey: Data, gnosis: GnosisRegistrator) {
        self.gnosis = gnosis
        self.cardId = cardId
        self.cardPublicKey = cardPublicKey
        self.walletPublicKey = walletPublicKey
        // updateState()
    }

    func setAccessCode(_ accessCode: String) {
        self.accessCode = accessCode
    }

    func setPin(_ pin: String) {
        do {
            try assertPinValid(pin)
            self.pin = pin
            updateState(with: .registration)
        } catch {
            self.error = (error as! SaltPayRegistratorError).alertBinder
        }
    }

    func onFinishKYC() {
        registerKYCIfNeeded()
            .sink { [weak self] completion in
                if case let .failure(error) = completion {
                    self?.error = error.alertBinder
                }
            } receiveValue: { _ in }
            .store(in: &bag)
    }

    func update() {
        isBusy = true

        updatePublisher()
            .sink { [weak self] completion in
                if case let .failure(error) = completion {
                    self?.error = error.alertBinder
                }

                self?.isBusy = false
            } receiveValue: { _ in }
            .store(in: &bag)
    }

    func updatePublisher() -> AnyPublisher<Void, Error> {
        checkGasIfNeeded()
            .flatMap { [weak self] _ -> AnyPublisher<Void, Error> in
                guard let self = self else { return .anyFail(error: SaltPayRegistratorError.empty) }

                return self.registerKYCIfNeeded()
            }
            .flatMap { [weak self] _ -> AnyPublisher<State, Error> in
                guard let self = self else { return .anyFail(error: SaltPayRegistratorError.empty) }

                return self.checkRegistration()
            }
            .handleEvents(receiveOutput: { [weak self] newState in
                self?.updateState(with: newState)
            }, receiveCompletion: { [weak self] completion in
                if case let .failure(error) = completion,
                   case SaltPayRegistratorError.noGas = error {
                    self?.state = .noGas
                }
            })
            .map { _ in
                return ()
            }
            .eraseToAnyPublisher()
    }

    func register() {
        isBusy = true

        checkGasIfNeeded()
            .flatMap { [weak self] _ -> AnyPublisher<AttestationResponse, Error> in
                guard let self = self else { return .anyFail(error: SaltPayRegistratorError.empty) }

                return self.api.requestAttestationChallenge(for: self.cardId, publicKey: self.cardPublicKey)
            }
            .flatMap { [weak self] attestationResponse -> AnyPublisher<RegistrationTask.Response, Error> in
                guard let self = self else { return .anyFail(error: SaltPayRegistratorError.empty) }

                let task = RegistrationTask(gnosis: self.gnosis,
                                            challenge: attestationResponse.challenge,
                                            walletPublicKey: self.walletPublicKey,
                                            approvalValue: self.approvalValue,
                                            spendLimitValue: self.spendLimitValue)

                self.registrationTask = task

                return self.tangemSdkProvider.sdk.startSessionPublisher(with: task,
                                                                        cardId: self.cardId,
                                                                        initialMessage: nil,
                                                                        accessCode: self.accessCode)
                    .eraseToAnyPublisher()
                    .eraseError()
            }
            .flatMap { [gnosis] response -> AnyPublisher<RegistrationTask.RegistrationTaskResponse, Error> in
//                return Just(response) // [REDACTED_TODO_COMMENT]
//                    .delay(for: .seconds(5), scheduler: DispatchQueue.global())
//                    .setFailureType(to: Error.self)
//                    .eraseToAnyPublisher()
                return gnosis.sendTransactions(response.signedTransactions)
                    .map { result -> RegistrationTask.RegistrationTaskResponse in
                        return response
                    }
                    .eraseToAnyPublisher()
            }
            .flatMap { [weak self] response -> AnyPublisher<RegisterWalletResponse, Error> in
                guard let self = self else { return .anyFail(error: SaltPayRegistratorError.empty) }

                guard let pin = self.pin else {
                    return .anyFail(error: SaltPayRegistratorError.needPin)
                }

                let cardSalt = response.attestResponse.publicKeySalt ?? Data()
                let cardSignature = response.attestResponse.cardSignature ?? Data()

                let request = ReqisterWalletRequest(cardId: self.cardId,
                                                    publicKey: self.cardPublicKey,
                                                    walletPublicKey: self.walletPublicKey,
                                                    walletSalt: response.attestResponse.salt,
                                                    walletSignature: response.attestResponse.walletSignature,
                                                    cardSalt: cardSalt,
                                                    cardSignature: cardSignature,
                                                    pin: pin)

                return self.api.registerWallet(request: request)
                    // .replaceError(with: RegisterWalletResponse(error: nil, errorCode: nil, success: true)) //[REDACTED_TODO_COMMENT]
                    // .setFailureType(to: Error.self) //[REDACTED_TODO_COMMENT]
                    .eraseToAnyPublisher()
            }
            .sink { [weak self] completion in
                if case let .failure(error) = completion {
                    self?.error = error.alertBinder
                }

                self?.isBusy = false
            } receiveValue: { [weak self] sendedTxs in
                self?.updateState(with: .kycStart)
            }
            .store(in: &bag)
    }

    private func updateState(with newState: State) {
        print("Saltpay. Update state from \(self.state) to \(newState)")

        if newState != state {
            self.state = newState
        }
    }

    private func registerKYCIfNeeded() -> AnyPublisher<Void, Error> {
        guard state == .kycStart else {
            return .justWithError(output: ())
        }

        let request = RegisterKYCRequest(cardId: cardId,
                                         publicKey: cardPublicKey,
                                         kycProvider: "UTORG",
                                         kycRefId: kycRefId)

        return api.registerKYC(request: request)
            .handleEvents(receiveOutput: { [weak self] response in
                self?.updateState(with: .kycWaiting)
            })
            .map { _ in }
            .eraseToAnyPublisher()
    }

    private func checkGasIfNeeded() -> AnyPublisher<Void, Error> {
        if state == .kycStart || state == .kycWaiting || state == .finished {
            return .justWithError(output: ())
        }

        return gnosis.checkHasGas()
            .tryMap { hasGas in
                if hasGas {
                    return ()
                } else {
                    throw SaltPayRegistratorError.noGas
                }
            }
            .eraseToAnyPublisher()
    }

    private func checkRegistration() -> AnyPublisher<State, Error> {
        api.checkRegistration(for: cardId, publicKey: cardPublicKey)
            .eraseToAnyPublisher()
    }

    private func assertPinValid(_ pin: String) throws {
        let array = Array(pin)

        if array.count < Constants.pinLength {
            throw SaltPayRegistratorError.weakPin
        }

        for char in array[1...] {
            if array[0] != char {
                return
            }
        }

        throw SaltPayRegistratorError.weakPin
    }
}

extension SaltPayRegistrator {
    enum Constants {
        static let pinLength: Int = 4
    }
}

extension SaltPayRegistrator {
    enum State: Equatable {
        case needPin
        case noGas

        case registration

        case kycStart
        case kycWaiting
        case finished

        init(from response: RegistrationResponse.Item) throws {
            guard response.passed == true else { // passed is false, show error
                throw SaltPayRegistratorError.cardNotPassed
            }

            if response.disabledByAdmin == true { // disabledByAdmin is true, show error
                throw SaltPayRegistratorError.cardDisabled
            }

            if response.active == true { // active is true, go to success screen
                self = .finished
                return
            }

            if response.pinSet == false {
                self = .needPin // pinset is false, go topin screen
                return
            }

            if response.kycDate != nil { // kycDate is set, go to kyc waiting screen
                self = .kycWaiting
                return
            }

            self = .kycStart  // pinset is true, go to kyc start screen
        }
    }
}
