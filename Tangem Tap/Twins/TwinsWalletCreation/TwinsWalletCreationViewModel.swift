//
//  TwinsWalletCreationViewModel.swift
//  Tangem Tap
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Combine
import SwiftUI

class TwinsWalletCreationViewModel: ViewModel {
	
	enum Step: Int, Comparable, CaseIterable {
		static func < (lhs: TwinsWalletCreationViewModel.Step, rhs: TwinsWalletCreationViewModel.Step) -> Bool {
			lhs.rawValue < rhs.rawValue
		}
		
		case first = 1, second, third, dismiss
		
		var cardNumberToInteractWith: Int {
			switch self {
			case .second: return 2
			default: return 1
			}
		}
		
		var stepTitle: String {
			String(format: "details_twins_recreate_step_format".localized, rawValue)
		}
		
		var hint: LocalizedStringKey {
			"details_twins_recreate_subtitle"
		}
		
		func nextStep() -> Step {
			switch self {
			case .first: return .second
			case .second: return .third
			default: return .dismiss
			}
		}
		
		static func uiStep(from step: TwinsWalletCreationService.CreationStep) -> Step {
			switch step {
			case .first: return .first
			case .second: return .second
			case .third: return .third
			case .done: return .dismiss
			}
		}
	}
	
	@Published var navigation: NavigationCoordinator!
	@Published var step: Step = .first
	@Published var error: AlertBinder?
	@Published var finishedWalletCreation: Bool = false
	@Published var firstTwinCardImage: UIImage = UIImage()
	@Published var secondTwinCardImage: UIImage = UIImage()
	
	var title: String { String(format: "details_twins_recreate_title_format".localized, walletCreationService.stepCardNumber) }
	var buttonTitle: LocalizedStringKey { LocalizedStringKey(String(format: "details_twins_recreate_button_format".localized, walletCreationService.stepCardNumber)) }
	
	var isDismissing: Bool = false
	
	private var isFirstTimeAppeared: Bool = false
	
	weak var assembly: Assembly!
	weak var imageLoaderService: ImageLoaderService!
	
	let isRecreatingWallet: Bool
	
	var walletCreationService: TwinsWalletCreationService
	
	private var bag = Set<AnyCancellable>()
	
	init(isRecreatingWallet: Bool, walletCreationService: TwinsWalletCreationService, imageLoaderService: ImageLoaderService) {
		self.isRecreatingWallet = isRecreatingWallet
		self.walletCreationService = walletCreationService
		self.imageLoaderService = imageLoaderService
		loadImages()
	}
	
	func buttonAction() {
		walletCreationService.executeCurrentStep()
	}
	
	func onDismiss() {
		walletCreationService.resetSteps()
	}
	
	func onAppear() {
		if isFirstTimeAppeared { return }
		isFirstTimeAppeared = true
		error = nil
		bind()
	}
	
	private func bind() {
		walletCreationService.step
			.receive(on: DispatchQueue.main)
			.sink(receiveValue: { [weak self] in
				if $0 == .done {
					self?.done()
				} else {
					self?.step = .uiStep(from: $0)
				}
			})
			.store(in: &bag)
		
		walletCreationService.occuredError
			.receive(on: DispatchQueue.main)
			.filter {
				if case .userCancelled = $0.toTangemSdkError() {
					return false
				}
				return true
			}
			.sink(receiveValue: { [weak self] in
				self?.error = $0.alertBinder
			})
			.store(in: &bag)
	}
	
	private func loadImages() {
		imageLoaderService.backedLoadImage(.twinCardOne)
			.receive(on: DispatchQueue.main)
			.sink(receiveCompletion: { _ in },
				  receiveValue: { [weak self] image in
					self?.firstTwinCardImage = image
				  })
			.store(in: &bag)
		imageLoaderService.backedLoadImage(.twinCardTwo)
			.receive(on: DispatchQueue.main)
			.sink(receiveCompletion: { _ in },
				  receiveValue: { [weak self] image in
					self?.secondTwinCardImage = image
				  })
			.store(in: &bag)
	}
	
	private func done() {
		self.finishedWalletCreation = true
	}
	
}
