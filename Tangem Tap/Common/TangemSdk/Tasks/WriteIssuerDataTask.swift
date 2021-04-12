//
//  WriteIssuerDataTask.swift
//  Tangem Tap
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import TangemSdk

    class WriteIssuerDataTask: CardSessionRunnable {
    typealias CommandResponse = WriteIssuerDataResponse
    
    var message: Message? { Message(header: "twin_process_creating_wallet".localized) }
    
    private let pairPubKey: Data
    private let keys: KeyPair
    
    private var signedPubKeyHash: Data!
    
    init(pairPubKey: Data, keys: KeyPair) {
        self.pairPubKey = pairPubKey
        self.keys = keys
    }
    
    func run(in session: CardSession, completion: @escaping CompletionResult<WriteIssuerDataResponse>) {
        let sign = SignCommand(hashes: [pairPubKey.sha256()], walletIndex: .index(TangemSdkConstants.oldCardDefaultWalletIndex))
        sign.run(in: session) { (result) in
            switch result {
            case .success(let response):
                self.signedPubKeyHash = response.signatures.first
                self.readIssuerCounter(in: session, completion: completion)
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    private func readIssuerCounter(in session: CardSession, completion: @escaping CompletionResult<WriteIssuerDataResponse>) {
        let readCommand = ReadIssuerDataCommand()
        readCommand.run(in: session) { (result) in
            switch result {
            case .success(let response):
                self.writeIssuerData(in: session, counter: response.issuerDataCounter, completion: completion)
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    private func writeIssuerData(in session: CardSession, counter: Int?, completion: @escaping CompletionResult<WriteIssuerDataResponse>) {
        guard let cardId = session.environment.card?.cardId else {
            completion(.failure(.cardError))
            return
        }
        
        let dataToSign = pairPubKey + signedPubKeyHash
        let newCounter = (counter ?? 0) + 1
        
        let hashes = FileHashHelper.prepareHash(for: cardId, fileData: dataToSign, fileCounter: newCounter, privateKey: keys.privateKey)
        guard
            let signature = hashes.finalizingSignature
        else {
            completion(.failure(.signHashesNotAvailable))
            return
        }
        
        let command = WriteIssuerDataCommand(issuerData: dataToSign,
                                             issuerDataSignature: signature,
                                             issuerDataCounter: newCounter,
                                             issuerPublicKey: keys.publicKey)
        command.run(in: session) { (result) in
            switch result {
            case .success(let response):
                completion(.success(response))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
}
