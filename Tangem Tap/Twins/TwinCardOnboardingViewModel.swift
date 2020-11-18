//
//  TwinCardOnboardingViewModel.swift
//  Tangem Tap
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Combine

class TwinCardOnboardingViewModel: ViewModel {
	
	enum State {
		case onboarding, warning
		
		var backgroundName: String {
			switch self {
			case .onboarding: return "TwinBackGrey"
			case .warning: return "TwinBackOrange"
			}
		}
	}
	
	@Published var navigation: NavigationCoordinator!
	
	weak var assembly: Assembly!
	weak var imageLoader: ImageLoaderService!
	
	let state: State
	
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
				navigation.openMainFromTwinOnboarding = true
			}
		case .warning:
			navigation.openTwinCardWalletCreation = true
		}
		navigation.objectWillChange.send()
		objectWillChange.send()
	}
	
}
