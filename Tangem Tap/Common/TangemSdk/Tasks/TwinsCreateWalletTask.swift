//
//  TwinsCreateWalletTask.swift
//  Tangem Tap
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import TangemSdk

class TwinsCreateWalletTask: CardSessionRunnable {
	typealias CommandResponse = CreateWalletResponse
	
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
	
	func run(in session: CardSession, completion: @escaping CompletionResult<CreateWalletResponse>) {
        session.viewDelegate.showAlertMessage("twin_process_preparing_card".localized)
		if session.environment.card?.status == .empty {
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
	
	private func eraseWallet(in session: CardSession, completion: @escaping CompletionResult<CreateWalletResponse>) {
		let erase = PurgeWalletCommand()
		erase.run(in: session) { (result) in
			switch result {
			case .success:
                self.createWallet(in: session, completion: completion)
			case .failure(let error):
				completion(.failure(error))
			}
		}
	}
	
	private func createWallet(in session: CardSession, completion: @escaping CompletionResult<CreateWalletResponse>) {
		let createWalletCommand = CreateWalletTask()
		createWalletCommand.run(in: session) { (result) in
			switch result {
			case .success(let response):
				if let fileToWrite = self.fileToWrite {
					self.writePublicKeyFile(fileToWrite: fileToWrite, walletResponse: response, in: session, completion: completion)
				} else {
					completion(.success(response))
				}
			case .failure(let error):
				completion(.failure(error))
			}
		}
	}
	
	private func writePublicKeyFile(fileToWrite: Data, walletResponse: CreateWalletResponse, in session: CardSession, completion: @escaping CompletionResult<CreateWalletResponse>) {
//		let writeFileCommand = WriteFileCommand(dataToWrite: FileDataProtectedByPasscode(data: fileToWrite))
        let task = WriteIssuerDataTask(pairPubKey: fileToWrite, keys: SignerUtils.signerKeys)
        session.viewDelegate.showAlertMessage("twin_process_creating_wallet".localized)
        task.run(in: session) { (response) in
            switch response {
            case .success:
                completion(.success(walletResponse))
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
	
}
