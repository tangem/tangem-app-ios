//
//  TwinsFinalizeWalletCreationTask.swift
//  Tangem Tap
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import TangemSdk

class TwinsFinalizeWalletCreationTask: CardSessionRunnable {
	
	private let fileToWrite: Data
	var requiresPin2: Bool { true }
	
    init(fileToWrite: Data) {
		self.fileToWrite = fileToWrite
	}
	
	func run(in session: CardSession, completion: @escaping CompletionResult<TapScanTaskResponse>) {
        guard let card = session.environment.card else {
            completion(.failure(TangemSdkError.missingPreflightRead))
            return
        }
        
        guard let issuerKeys = SignerUtils.signerKeys(for: card.issuer.publicKey) else {
            completion(.failure(TangemSdkError.unknownError))
            return
        }
        
        let task = WriteIssuerDataTask(pairPubKey: fileToWrite, keys: issuerKeys)
        task.run(in: session) { (response) in
            switch response {
            case .success:
                self.readCard(in: session, completion: completion)
            case .failure(let error):
                completion(.failure(error))
            }
        }
//		let task = WriteFileCommand(dataToWrite: FileDataProtectedByPasscode(data: fileToWrite))
//		task.run(in: session, completion: { (result) in
//			switch result {
//			case .success:
//				self.readCard(in: session, completion: completion)
//			case .failure(let error):
//				completion(.failure(error))
//			}
//		})
	}
	
	func readCard(in session: CardSession, completion: @escaping CompletionResult<TapScanTaskResponse>) {
        let task = TapScanTask()
		task.run(in: session, completion: completion)
	}
	
}
