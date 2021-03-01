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
    private unowned var validatedCardsService: ValidatedCardsService
	
	var requiresPin2: Bool { true }
	
    init(fileToWrite: Data, validatedCardsService: ValidatedCardsService) {
		self.fileToWrite = fileToWrite
        self.validatedCardsService = validatedCardsService
	}
	
	func run(in session: CardSession, completion: @escaping CompletionResult<TapScanTaskResponse>) {
        let task = WriteIssuerDataTask(pairPubKey: fileToWrite, keys: SignerUtils.signerKeys)
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
        let task = TapScanTask(validatedCardsService: validatedCardsService)
		task.run(in: session, completion: completion)
	}
	
}
