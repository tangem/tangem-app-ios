//
//  TwinsWalletCreationService.swift
//  Tangem Tap
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemSdk

class TwinsWalletCreationService {
	
	enum CreationStep {
		case first, second, third, done
	}
	
	private let twinFileName = "twinPublicKey"
	
	private let tangemSdk: TangemSdk
	private let twinFileEncoder: TwinCardFileEncoder
	
	private let firstTwinCid: String
	private let secondTwinCid: String
	
	private var firstTwinPublicKey: Data?
	private var secondTwinPublicKey: Data?
	
	private(set) var step = CurrentValueSubject<CreationStep, Never>(.first)
	private(set) var occuredError = PassthroughSubject<Error, Never>()
	
	init(tangemSdk: TangemSdk, twinFileEncoder: TwinCardFileEncoder, twinInfo: TwinCardInfo) {
		self.tangemSdk = tangemSdk
		self.twinFileEncoder = twinFileEncoder
		if twinInfo.series.number == 1 {
			firstTwinCid = twinInfo.cid
			secondTwinCid = twinInfo.pairCid
		} else {
			firstTwinCid = twinInfo.pairCid
			secondTwinCid = twinInfo.cid
		}
	}
	
	func executeCurrentStep() {
		switch step.value {
		case .first:
			createWalletOnFirstCard()
		case .second:
			createWalletOnSecondCard()
		case .third:
			writeSecondPublicKeyToFirst()
		case .done:
			step.send(.done)
		}
	}
	
	private func createWalletOnFirstCard() {
		let task = TwinsCreateWalletTask(targetCid: firstTwinCid, fileToWrite: nil)
		tangemSdk.startSession(with: task, cardId: firstTwinCid) { (result) in
			switch result {
			case .success(let response):
				self.firstTwinPublicKey = response.walletPublicKey
				self.step.send(.second)
			case .failure(let error):
				self.occuredError.send(error)
			}
		}
	}
	
	private func createWalletOnSecondCard() {
		guard let firstTwinKey = firstTwinPublicKey else {
			step.send(.first)
			occuredError.send(TangemSdkError.missingIssuerPublicKey)
			return
		}
		
		switch twinFileToWrite(publicKey: firstTwinKey) {
		case .success(let file):
			let task = TwinsCreateWalletTask(targetCid: secondTwinCid, fileToWrite: file)
			tangemSdk.startSession(with: task, cardId: secondTwinCid) { (result) in
				switch result {
				case .success(let response):
					self.secondTwinPublicKey = response.walletPublicKey
					self.step.send(.third)
				case .failure(let error):
					self.occuredError.send(error)
				}
			}
		case .failure(let error):
			occuredError.send(error)
		}
		
	}
	
	private func writeSecondPublicKeyToFirst() {
		guard let secondTwinKey = secondTwinPublicKey else {
			step.send(.second)
			occuredError.send(TangemSdkError.missingIssuerPublicKey)
			return
		}
		
		switch twinFileToWrite(publicKey: secondTwinKey) {
		case .success(let file):
			let task = WriteFileCommand(dataToWrite: FileDataProtectedByPasscode(data: file))
			tangemSdk.startSession(with: task, cardId: firstTwinCid) { (result) in
				switch result {
				case .success:
					self.step.send(.done)
				case .failure(let error):
					self.occuredError.send(error)
				}
			}
		case .failure(let error):
			occuredError.send(error)
		}
		
	}
	
	private func twinFileToWrite(publicKey: Data) -> Result<Data, Error> {
		do {
			let data = try twinFileEncoder.encode(TwinCardFile(publicKey: publicKey, fileTypeName: twinFileName))
			return .success(data)
		} catch {
			print("Failed to encode twin file:", error)
			return .failure(error)
		}
	}
	
}
