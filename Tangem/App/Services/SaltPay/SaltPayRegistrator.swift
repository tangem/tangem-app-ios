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
    
    private let repo: SaltPayRepo = .init()
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
        //updateState()
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
        updateState(with: .kycWaiting)

        let request = RegisterKYCRequest(cardId: cardId,
                                         publicKey: cardPublicKey,
                                         kycProvider: "UTORG",
                                         kycRefId: kycRefId)

        api.registerKYC(request: request)
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
            .flatMap { [weak self] _ -> AnyPublisher<State, Error>  in
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

        api.requestAttestationChallenge(for: cardId, publicKey: cardPublicKey)
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
                self?.repo.data.transactionsSent = true
                self?.updateState(with: .kycStart)
            }
            .store(in: &bag)
    }

    var counter = 0
    private func updateState(with newState: State) {
        // newState: State = newState

//        if repo.data.transactionsSent {
//            newState = .kycStart
//        } else if self.pin != nil {
//            newState = .registration
//        }

        if newState != state {
            self.state = newState
        }

        // self.state = .kycStart //[REDACTED_TODO_COMMENT]
    }

    private func checkGasIfNeeded() -> AnyPublisher<Void, Error> {
        if state == .kycStart || state == .kycWaiting {
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

enum SaltPayRegistratorError: String, Error, LocalizedError {
    case failedToMakeTxData
    case needPin
    case empty
    case noGas
    case emptyResponse
    case card
    case cardNotPassed
    case cardDisabled
    case emptyBackupCardScanned
    case weakPin


    var errorDescription: String? {
        self.rawValue
    }

    var alertBinder: AlertBinder {
        switch self {
        case .weakPin:
            return .init(title: "saltpay_error_pin_weak_title".localized,
                         message: "saltpay_error_pin_weak_message".localized)
        case .emptyBackupCardScanned:
            return .init(title: "saltpay_error_empty_backup_title".localized,
                         message: "saltpay_error_empty_backup_message".localized)
        case .noGas:
            return .init(title: "saltpay_error_no_gas_title".localized,
                         message: "saltpay_error_no_gas_message".localized)
        default:
            return .init(alert: alert, error: self)
        }
    }
}

// MARK: - Gnosis chain

class GnosisRegistrator {
    private let settings: GnosisRegistrator.Settings
    private let walletManager: WalletManager
    private var transactionProcessor: EthereumTransactionProcessor { walletManager as! EthereumTransactionProcessor }
    private let cardAddress: String

    init(settings: GnosisRegistrator.Settings, walletPublicKey: Data, cardPublicKey: Data, factory: WalletManagerFactory) throws {
        self.settings = settings
        self.walletManager = try factory.makeWalletManager(blockchain: settings.blockchain, walletPublicKey: walletPublicKey)
        self.cardAddress = try Blockchain.ethereum(testnet: false).makeAddresses(from: cardPublicKey, with: nil)[0].value
    }

    func checkHasGas() -> AnyPublisher<Bool, Error> {
        walletManager.updatePublisher()
            .map { wallet -> Bool in
                if let coinAmount = wallet.amounts[.coin] {
                    return !coinAmount.isZero
                } else {
                    return false
                }
            }
            .eraseToAnyPublisher()
    }

    func sendTransactions(_ transactions: [SignedEthereumTransaction]) -> AnyPublisher<Void, Error> {
        let sortedByNonce = transactions.sorted { $0.transaction.nonce < $1.transaction.nonce }
        let publishers = sortedByNonce.map { transactionProcessor.send($0) }

        let start = Just("").setFailureType(to: Error.self).eraseToAnyPublisher()
        let pipe = publishers.reduce(start) { partialResult, nextPublisher in
            partialResult.flatMap { _ in nextPublisher }.eraseToAnyPublisher()
        }

        return pipe
            .map { _ in return () }
            .eraseToAnyPublisher()
    }

    func makeSetSpendLimitTx(value: Decimal) -> AnyPublisher<CompilledEthereumTransaction, Error>  {
        do {
            let limitAmount = Amount(with: settings.token, value: value)
            let setSpedLimitData = try makeTxData(sig: Signatures.setSpendLimit, address: cardAddress, amount: limitAmount)

            return transactionProcessor.getFee(to: settings.otpProcessorContractAddress, data: "0x\(setSpedLimitData.hexString)", amount: nil)
                //  .replaceError(with: [Amount(with: settings.blockchain, value: 0.00001), Amount(with: settings.blockchain, value: 0.00001)]) //[REDACTED_TODO_COMMENT]
                .tryMap { fees -> Transaction in
                    let params = EthereumTransactionParams(data: setSpedLimitData, nonce: self.transactionProcessor.initialNonce)
                    var transaction = try self.walletManager.createTransaction(amount: Amount.zeroCoin(for: self.settings.blockchain),
                                                                               fee: fees[1],
                                                                               destinationAddress: self.settings.otpProcessorContractAddress,
                                                                               sourceAddress: self.cardAddress)
                    transaction.params = params

                    return transaction
                }
                .flatMap { [transactionProcessor] tx in
                    transactionProcessor.buildForSign(tx)
                }
                .eraseToAnyPublisher()
        } catch {
            return .anyFail(error: error)
        }
    }

    func makeInitOtpTx(rootOTP: Data, rootOTPCounter: Int) -> AnyPublisher<CompilledEthereumTransaction, Error>  {
        let initOTPData = Signatures.initOTP + rootOTP.prefix(16) + Data(count: 46) + rootOTPCounter.bytes2

        return transactionProcessor.getFee(to: settings.otpProcessorContractAddress, data: "0x\(initOTPData.hexString)", amount: nil)
            // .replaceError(with: [Amount(with: settings.blockchain, value: 0.00001), Amount(with: settings.blockchain, value: 0.00001)]) //[REDACTED_TODO_COMMENT]
            .tryMap { fees -> Transaction in
                let params = EthereumTransactionParams(data: initOTPData, nonce: self.transactionProcessor.initialNonce + 1)
                var transaction = try self.walletManager.createTransaction(amount: Amount.zeroCoin(for: self.settings.blockchain),
                                                                           fee: fees[1],
                                                                           destinationAddress: self.settings.otpProcessorContractAddress,
                                                                           sourceAddress: self.cardAddress)
                transaction.params = params

                return transaction
            }
            .flatMap { [transactionProcessor] tx in
                transactionProcessor.buildForSign(tx)
            }
            .eraseToAnyPublisher()
    }

    func makeSetWalletTx() -> AnyPublisher<CompilledEthereumTransaction, Error>  {
        do {
            let setWalletData = try makeTxData(sig: Signatures.setWallet, address: cardAddress, amount: nil)

            return transactionProcessor.getFee(to: settings.otpProcessorContractAddress, data: "0x\(setWalletData.hexString)", amount: nil)
                //   .replaceError(with: [Amount(with: settings.blockchain, value: 0.00001), Amount(with: settings.blockchain, value: 0.00001)]) //[REDACTED_TODO_COMMENT]
                .tryMap { fees -> Transaction in
                    let params = EthereumTransactionParams(data: setWalletData, nonce: self.transactionProcessor.initialNonce + 2)
                    var transaction = try self.walletManager.createTransaction(amount: Amount.zeroCoin(for: self.settings.blockchain),
                                                                               fee: fees[1],
                                                                               destinationAddress: self.settings.otpProcessorContractAddress,
                                                                               sourceAddress: self.cardAddress)
                    transaction.params = params

                    return transaction
                }
                .flatMap { [transactionProcessor] tx in
                    transactionProcessor.buildForSign(tx)
                }
                .eraseToAnyPublisher()
        } catch {
            return .anyFail(error: error)
        }
    }

    func makeApprovalTx(value: Decimal) -> AnyPublisher<CompilledEthereumTransaction, Error>  {
        let approveAmount = Amount(with: settings.token, value: value)
        let zeroApproveAmount = Amount(with: approveAmount, value: 0)
        do {
            let approveData = try makeTxData(sig: Signatures.approve, address: settings.otpProcessorContractAddress, amount: approveAmount)

            return transactionProcessor.getFee(to: settings.token.contractAddress, data: "0x\(approveData.hexString)", amount: nil)
                //   .replaceError(with: [Amount(with: settings.blockchain, value: 0.00001), Amount(with: settings.blockchain, value: 0.00001)]) //[REDACTED_TODO_COMMENT]
                .tryMap { fees -> Transaction in
                    let params = EthereumTransactionParams(data: approveData, nonce: self.transactionProcessor.initialNonce + 3)
                    var transaction = try self.walletManager.createTransaction(amount: zeroApproveAmount,
                                                                               fee: fees[1],
                                                                               destinationAddress: "")
                    transaction.params = params

                    return transaction
                }
                .flatMap { [transactionProcessor] tx in
                    transactionProcessor.buildForSign(tx)
                }
                .eraseToAnyPublisher()
        } catch {
            return .anyFail(error: error)
        }
    }

    private func makeTxData(sig: Data, address: String, amount: Amount?) throws -> Data {
        let addressData = Data(hexString: address).aligned()

        guard let amount = amount else {
            return sig + addressData
        }

        guard let amountValue = amount.bigUIntValue else {
            throw SaltPayRegistratorError.failedToMakeTxData
        }

        let amountString = String(amountValue, radix: 16).remove("0X")
        let amountData = Data(hex: amountString).aligned()

        return sig + addressData + amountData
    }
}

extension GnosisRegistrator {
    enum Signatures {
        static let approve: Data = "approve(address,uint256)".signedPrefix
        static let setSpendLimit: Data = "setSpendLimit(address,uint256)".signedPrefix
        static let initOTP: Data = "initOTP(bytes16,uint16)".signedPrefix // 0x0ac81ec3
        static let setWallet: Data = "setWallet(address)".signedPrefix // 0xdeaa59df
    }
}

extension GnosisRegistrator {
    enum Settings {
        case main
        case testnet

        var token: Token {
            .init(sdkToken, id: "wrapped-xdai")
        }

        var otpProcessorContractAddress: String {
            switch self {
            case .main:
                return "0x3B4397C817A26521Df8bD01a949AFDE2251d91C2"
            case .testnet:
                return "0x710BF23486b549836509a08c184cE0188830f197"
            }
        }

        var blockchain: Blockchain {
            switch self {
            case .main:
                return Blockchain.saltPay(testnet: false)
            case .testnet:
                return Blockchain.saltPay(testnet: true)
            }
        }

        private var sdkToken: WalletData.Token {
            switch self {
            case .main:
                return .init(name: "WXDAI",
                             symbol: "WXDAI",
                             contractAddress: "0x4346186e7461cB4DF06bCFCB4cD591423022e417",
                             decimals: 18)
            case .testnet:
                return .init(name: "WXDAI Test",
                             symbol: "MyERC20",
                             contractAddress: "0x69cca8D8295de046C7c14019D9029Ccc77987A48",
                             decimals: 0)
            }
        }
    }
}

fileprivate extension String {
    var signedPrefix: Data {
        self.data(using: .utf8)!.sha3(.keccak256).prefix(4)
    }
}

// MARK: - Permanent storage

struct SaltPayRegistratorData: Codable {
    var transactionsSent: Bool = false
}

class SaltPayRepo {
    private let storageKey: String = "saltpay_registration_data"
    private let storage = SecureStorage()
    private var isFetching: Bool = false

    var data: SaltPayRegistratorData = .init() {
        didSet {
            try? save()
        }
    }

    init() {
        try? fetch()
    }

    func reset() {
        try? storage.delete(storageKey)
        data = .init()
    }

    private func save() throws {
        guard !isFetching else { return }

        let encoded = try JSONEncoder().encode(data)
        try storage.store(encoded, forKey: storageKey)
    }

    private func fetch() throws {
        self.isFetching = true
        defer { self.isFetching = false }

        if let savedData = try storage.get(storageKey) {
            self.data = try JSONDecoder().decode(SaltPayRegistratorData.self, from: savedData)
        }
    }
}


// MARK: - Registration task

fileprivate class RegistrationTask: CardSessionRunnable {
    private weak var gnosis: GnosisRegistrator? = nil
    private var challenge: Data
    private let approvalValue: Decimal
    private let spendLimitValue: Decimal
    private let walletPublicKey: Data

    private var generateOTPCommand: GenerateOTPCommand? = nil
    private var attestWalletCommand: AttestWalletKeyCommand? = nil
    private var signCommand: SignHashesCommand? = nil

    private var generateOTPResponse: GenerateOTPResponse? = nil
    private var attestWalletResponse: AttestWalletKeyResponse? = nil
    private var signedTransactions: [SignedEthereumTransaction] = []

    private var bag: Set<AnyCancellable> = .init()

    init(gnosis: GnosisRegistrator,
         challenge: Data,
         walletPublicKey: Data,
         approvalValue: Decimal,
         spendLimitValue: Decimal) {
        self.gnosis = gnosis
        self.challenge = challenge
        self.walletPublicKey = walletPublicKey
        self.approvalValue = approvalValue
        self.spendLimitValue = spendLimitValue
    }

    deinit {
        print("RegistrationTask deinit")
    }

    func run(in session: CardSession, completion: @escaping CompletionResult<RegistrationTaskResponse>) {
        generateOTP(in: session, completion: completion)
    }

    private func generateOTP(in session: CardSession, completion: @escaping CompletionResult<RegistrationTaskResponse>) {
        let cmd = GenerateOTPCommand()
        self.generateOTPCommand = cmd
        session.viewDelegate.showAlertMessage("Card is preparing...") // [REDACTED_TODO_COMMENT]

        cmd.run(in: session) { result in
            switch result {
            case .success(let response):
                self.generateOTPResponse = response
                self.attestWallet(in: session, completion: completion)
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    private func attestWallet(in session: CardSession, completion: @escaping CompletionResult<RegistrationTaskResponse>) {
        guard let card = session.environment.card else {
            completion(.failure(.missingPreflightRead))
            return
        }

        guard let walletPublicKey = card.wallets.first?.publicKey,
              walletPublicKey == self.walletPublicKey else {
            completion(.failure(.walletNotFound))
            return
        }

        let cmd = AttestWalletKeyCommand(publicKey: walletPublicKey,
                                         challenge: self.challenge,
                                         confirmationMode: .dynamic)

        self.attestWalletCommand = cmd
        session.viewDelegate.showAlertMessage("Binding the wallet...") // [REDACTED_TODO_COMMENT]

        cmd.run(in: session) { result in
            switch result {
            case .success(let response):
                self.attestWalletResponse = response
                self.prepareTransactions(in: session, completion: completion)
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    private func prepareTransactions(in session: CardSession, completion: @escaping CompletionResult<RegistrationTaskResponse>) {
        guard let gnosis = self.gnosis,
              let generateOTPResponse = self.generateOTPResponse else {
            completion(.failure(.unknownError))
            return
        }

        let txPublishers = [
            gnosis.makeApprovalTx(value: approvalValue),
            gnosis.makeSetWalletTx(),
            gnosis.makeInitOtpTx(rootOTP: generateOTPResponse.rootOTP, rootOTPCounter: generateOTPResponse.rootOTPCounter),
            gnosis.makeSetSpendLimitTx(value: spendLimitValue),
        ]

        session.viewDelegate.showAlertMessage("Preparing blockchain transactions...") // [REDACTED_TODO_COMMENT]

        Publishers
            .MergeMany(txPublishers)
            .collect()
            .sink { completionResult in
                if case let .failure(error) = completionResult {
                    completion(.failure(error.toTangemSdkError()))
                }
            } receiveValue: { compilledTransactions in
                self.signTransactions(compilledTransactions, in: session, completion: completion)
            }
            .store(in: &bag)
    }

    private func signTransactions(_ transactions: [CompilledEthereumTransaction],
                                  in session: CardSession,
                                  completion: @escaping CompletionResult<RegistrationTaskResponse>) {
        guard let walletPublicKey = session.environment.card?.wallets.first?.publicKey else {
            completion(.failure(.walletNotFound))
            return
        }

        let hashes = transactions.map { $0.hash }
        let cmd = SignHashesCommand(hashes: hashes, walletPublicKey: walletPublicKey)
        self.signCommand = cmd

        session.viewDelegate.showAlertMessage("Signing blockchain transactions...") // [REDACTED_TODO_COMMENT]

        cmd.run(in: session) { result in
            switch result {
            case .success(let response):
                let signedTxs = zip(transactions, response.signatures).map { (tx, signature) in
                    SignedEthereumTransaction(compilledTransaction: tx, signature: signature)
                }

                self.signedTransactions = signedTxs
                session.viewDelegate.showAlertMessage("Card interaction complete successfully") // [REDACTED_TODO_COMMENT]
                self.complete(completion: completion)
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    private func complete(completion: @escaping CompletionResult<RegistrationTaskResponse>) {
        guard let attestWalletResponse = self.attestWalletResponse,
              !self.signedTransactions.isEmpty else {
            completion(.failure(.unknownError))
            return
        }

        let response = RegistrationTaskResponse(signedTransactions: signedTransactions,
                                                attestResponse: attestWalletResponse)

        completion(.success(response))
    }
}

fileprivate extension RegistrationTask {
    struct RegistrationTaskResponse {
        let signedTransactions: [SignedEthereumTransaction]
        let attestResponse: AttestWalletKeyResponse
    }
}

fileprivate extension Data {
    func aligned() -> Data {
        let bytesCount = self.count

        guard bytesCount < 32 else {
            return self
        }

        let prefix = Data(repeating: 0, count: 32 - bytesCount)

        return prefix + self
    }
}
