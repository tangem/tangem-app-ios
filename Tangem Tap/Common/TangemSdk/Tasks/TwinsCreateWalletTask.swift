//
//  TwinsCreateWalletTask.swift
//  Tangem Tap
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import TangemSdk

struct TwinsCreateWalletTaskResponse: JSONStringConvertible {
    let createWalletResponse: CreateWalletResponse
    let card: Card
}

class TwinsCreateWalletTask: CardSessionRunnable {
	typealias CommandResponse = TwinsCreateWalletTaskResponse
	
    var message: Message? { Message(header: "twin_process_preparing_card".localized) }
    
	var requiresPin2: Bool { true }
	
    deinit {
        print("Twins create wallet task deinited")
    }
    
	private let targetCid: String
	private var fileToWrite: Data?
	
	init(targetCid: String, fileToWrite: Data?) {
		self.targetCid = targetCid
		self.fileToWrite = fileToWrite
	}
	
	func run(in session: CardSession, completion: @escaping CompletionResult<CommandResponse>) {
        session.viewDelegate.showAlertMessage("twin_process_preparing_card".localized)
        guard let card = session.environment.card else {
            completion(.failure(.missingPreflightRead))
            return
        }
        
        if card.wallets.count == 0 {
            createWallet(in: session, completion: completion)
		} else {
			eraseWallet(in: session, completion: completion)
		}
	}
	
//	private func deleteFile(at index: Int? = nil, in session: CardSession, completion: @escaping CompletionResult<CreateWalletResponse>) {
//		let deleteFile = DeleteFilesTask(filesToDelete: index == nil ? nil : [index!])
//		deleteFile.run(in: session) { (result) in
//			switch result {
//			case .success:
//				self.createWallet(in: session, completion: completion)
//			case .failure(let error):
//				completion(.failure(error))
//			}
//		}
//	}
	
	private func eraseWallet(in session: CardSession, completion: @escaping CompletionResult<CommandResponse>) {
        let walletPublicKey = session.environment.card?.wallets.first?.publicKey
        let erase = PurgeWalletCommand(publicKey: walletPublicKey!)
		erase.run(in: session) { (result) in
			switch result {
			case .success:
                self.createWallet(in: session, completion: completion)
			case .failure(let error):
				completion(.failure(error))
			}
		}
	}
	
	private func createWallet(in session: CardSession, completion: @escaping CompletionResult<CommandResponse>) {
        let createWalletCommand = CreateWalletCommand(curve: .secp256k1, isPermanent: false)
		createWalletCommand.run(in: session) { (result) in
			switch result {
			case .success(let response):
				if let fileToWrite = self.fileToWrite {
					self.writePublicKeyFile(fileToWrite: fileToWrite, walletResponse: response, in: session, completion: completion)
				} else {
                    self.scanCard(session: session, walletResponse: response, completion: completion)
				}
			case .failure(let error):
				completion(.failure(error))
			}
		}
	}
	
	private func writePublicKeyFile(fileToWrite: Data, walletResponse: CreateWalletResponse, in session: CardSession, completion: @escaping CompletionResult<CommandResponse>) {
//		let writeFileCommand = WriteFileCommand(dataToWrite: FileDataProtectedByPasscode(data: fileToWrite))
        
        guard let issuerKeys = SignerUtils.signerKeys(for: session.environment.card!.issuer.name) else {
            completion(.failure(TangemSdkError.unknownError))
            return
        }
        
        let task = WriteIssuerDataTask(pairPubKey: fileToWrite, keys: issuerKeys)
        session.viewDelegate.showAlertMessage("twin_process_creating_wallet".localized)
        task.run(in: session) { (response) in
            switch response {
            case .success:
                self.scanCard(session: session, walletResponse: walletResponse, completion: completion)
            case .failure(let error):
                completion(.failure(error))
            }
        }
//		command.run(in: session) { (response) in
//			switch response {
//			case .success:
//				completion(.success(walletResponse))
//			case .failure(let error):
//				completion(.failure(error))
//			}
//		}
	}
    
    private func scanCard(session: CardSession, walletResponse: CreateWalletResponse, completion: @escaping CompletionResult<CommandResponse>) {
        let scanTask = TapScanTask()
        scanTask.run(in: session) { scanCompletion in
            switch scanCompletion {
            case .failure(let error):
                completion(.failure(error))
            case .success(let scanResponse):
                completion(.success(TwinsCreateWalletTaskResponse(createWalletResponse: walletResponse,
                                                                  card: scanResponse.card)))
            }
        }
    }
	
}
