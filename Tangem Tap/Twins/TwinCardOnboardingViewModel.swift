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
		case onboarding(withPairCid: String), warning
		
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
	}
	
	weak var navigation: NavigationCoordinator!
	weak var assembly: Assembly!
	weak var imageLoader: ImageLoaderService!
	weak var userPrefsService: UserPrefsService!
	
	var state: State
	
	private var bag = Set<AnyCancellable>()
	
	init(state: State) {
		self.state = state
	}
	
	func didAppear() {
		imageLoader.backedLoadImage(name: "")
			.sink(receiveCompletion: { _ in }, receiveValue: {
				print("Image received", $0)
			})
			.store(in: &bag)
	}
	
	func buttonAction() {
		switch state {
		case .onboarding:
			if navigation.showTwinCardOnboarding {
				navigation.showTwinCardOnboarding = false
			} else {
				navigation.onboardingOpenMain = true
			}
			userPrefsService.isTwinCardOnboardingWasDisplayed = true
		case .warning:
			navigation.onboardingOpenTwinCardWalletCreation = true
		}
	}
	
}
