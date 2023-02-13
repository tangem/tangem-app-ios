//
//  RegistrationTask.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemSdk
import BlockchainSdk

class RegistrationTask: CardSessionRunnable {
    private weak var gnosis: GnosisRegistrator?
    private var challenge: Data
    private let approvalValue: Decimal
    private let spendLimitValue: Decimal
    private let walletPublicKey: Data

    private var generateOTPCommand: GenerateOTPCommand?
    private var attestWalletCommand: AttestWalletKeyCommand?
    private var signCommand: SignHashesCommand?

    private var generateOTPResponse: GenerateOTPResponse?
    private var attestWalletResponse: AttestWalletKeyResponse?
    private var signedTransactions: [SignedEthereumTransaction] = []

    private var bag: Set<AnyCancellable> = .init()

    init(
        gnosis: GnosisRegistrator,
        challenge: Data,
        walletPublicKey: Data,
        approvalValue: Decimal,
        spendLimitValue: Decimal
    ) {
        self.gnosis = gnosis
        self.challenge = challenge
        self.walletPublicKey = walletPublicKey
        self.approvalValue = approvalValue
        self.spendLimitValue = spendLimitValue
    }

    deinit {
        AppLog.shared.debug("RegistrationTask deinit")
    }

    func run(in session: CardSession, completion: @escaping CompletionResult<RegistrationTaskResponse>) {
        session.viewDelegate.showAlertMessage(Localization.registrationTaskAlertMessage)
        generateOTP(in: session, completion: completion)
    }

    private func generateOTP(in session: CardSession, completion: @escaping CompletionResult<RegistrationTaskResponse>) {
        let cmd = GenerateOTPCommand()
        generateOTPCommand = cmd

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

        let cmd = AttestWalletKeyCommand(
            publicKey: walletPublicKey,
            challenge: challenge,
            confirmationMode: .dynamic
        )

        attestWalletCommand = cmd

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
        guard let gnosis = gnosis,
              let generateOTPResponse = generateOTPResponse else {
            completion(.failure(.unknownError))
            return
        }

        let txPublishers = [
            gnosis.makeApprovalTx(value: approvalValue),
            gnosis.makeSetWalletTx(),
            gnosis.makeInitOtpTx(rootOTP: generateOTPResponse.rootOTP, rootOTPCounter: generateOTPResponse.rootOTPCounter),
            gnosis.makeSetSpendLimitTx(value: spendLimitValue),
        ]

        Publishers
            .MergeMany(txPublishers)
            .collect()
            .sink { completionResult in
                if case .failure(let error) = completionResult {
                    completion(.failure(error.toTangemSdkError()))
                }
            } receiveValue: { compiledTransactions in
                self.signTransactions(compiledTransactions, in: session, completion: completion)
            }
            .store(in: &bag)
    }

    private func signTransactions(
        _ transactions: [CompiledEthereumTransaction],
        in session: CardSession,
        completion: @escaping CompletionResult<RegistrationTaskResponse>
    ) {
        guard let walletPublicKey = session.environment.card?.wallets.first?.publicKey else {
            completion(.failure(.walletNotFound))
            return
        }

        let hashes = transactions.map { $0.hash }
        let cmd = SignHashesCommand(hashes: hashes, walletPublicKey: walletPublicKey)
        signCommand = cmd

        cmd.run(in: session) { result in
            switch result {
            case .success(let response):
                let signedTxs = zip(transactions, response.signatures).map { tx, signature in
                    SignedEthereumTransaction(compiledTransaction: tx, signature: signature)
                }

                self.signedTransactions = signedTxs
                self.complete(completion: completion)
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    private func complete(completion: @escaping CompletionResult<RegistrationTaskResponse>) {
        guard let attestWalletResponse = attestWalletResponse,
              !self.signedTransactions.isEmpty else {
            completion(.failure(.unknownError))
            return
        }

        let response = RegistrationTaskResponse(
            signedTransactions: signedTransactions,
            attestResponse: attestWalletResponse
        )

        completion(.success(response))
    }
}

extension RegistrationTask {
    struct RegistrationTaskResponse {
        let signedTransactions: [SignedEthereumTransaction]
        let attestResponse: AttestWalletKeyResponse
    }
}
