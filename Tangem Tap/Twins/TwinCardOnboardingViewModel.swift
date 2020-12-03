//
//  TwinCardOnboardingViewModel.swift
//  Tangem Tap
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Combine
import SwiftUI

class TwinCardOnboardingViewModel: ViewModel {
	
	enum State: Equatable {
		case onboarding(withPairCid: String, isFromMain: Bool), warning
		
		var backgroundName: String {
			switch self {
			case .onboarding: return "TwinBackGrey"
			case .warning: return "TwinBackOrange"
			}
		}
		
		var buttonTitle: LocalizedStringKey {
			switch self {
			case .onboarding: return "common_continue"
			case .warning: return "common_start"
			}
		}
		
		var storageKey: String {
			switch self {
			case let .onboarding(withPairCid, isFromMain):
				return "onboarding_\(withPairCid)_\(isFromMain)"
			case .warning:
				return "onboarding_warning"
			}
		}
	}
	
	weak var navigation: NavigationCoordinator!
	weak var assembly: Assembly!
	weak var imageLoader: ImageLoaderService!
	weak var userPrefsService: UserPrefsService!
	
	@Published var firstTwinImage: UIImage = UIImage()
	@Published var secondTwinImage: UIImage = UIImage()
	
	var state: State
	
	private var bag = Set<AnyCancellable>()
	
	init(state: State, imageLoader: ImageLoaderService) {
		self.state = state
		self.imageLoader = imageLoader
		loadImages()
	}
	
	func loadImages() {
		imageLoader.backedLoadImage(.twinCardOne)
			.receive(on: DispatchQueue.main)
			.sink(receiveCompletion: { _ in },
				  receiveValue: { [weak self] image in
					self?.firstTwinImage = image
				  })
			.store(in: &bag)
		imageLoader.backedLoadImage(.twinCardTwo)
			.receive(on: DispatchQueue.main)
			.sink(receiveCompletion: { _ in },
				  receiveValue: { [weak self] image in
					self?.secondTwinImage = image
				  })
			.store(in: &bag)
	}
	
	func didAppear() {
	}
	
	func buttonAction() {
		switch state {
		case .onboarding(_, let isFromMain):
			if navigation.showTwinCardOnboarding {
				navigation.showTwinCardOnboarding = false
			} else if !isFromMain {
				navigation.onboardingOpenMain = true
			}
			userPrefsService.isTwinCardOnboardingWasDisplayed = true
		case .warning:
			navigation.onboardingOpenTwinCardWalletCreation = true
		}
	}
	
}
