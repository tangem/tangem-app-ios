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
        case onboarding(withPairCid: String, isFromMain: Bool)
        case warning(isRecreating: Bool)
		
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
			case let .onboarding(_, isFromMain):
				return "onboarding_\(isFromMain)"
			case .warning(let isRecreating):
				return "onboarding_warning_\(isRecreating)"
			}
		}
		
		var backgroundColorSet: TwinOnboardingBackground.ColorSet {
			switch self {
			case .onboarding: return .gray
			case .warning: return .orange
			}
		}
        
        var isRecreating: Bool {
            switch self {
            case .warning(let isRecreating):
                return isRecreating
            default:
                return false
            }
        }
        
        var isWarning: Bool {
            switch self {
            case .warning:
                return true
            default:
                return false
            }
        }
        
        var isFromMain: Bool {
            switch self {
            case let .onboarding(_, isFromMain):
                return isFromMain
            default:
                return false
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
	var appeared = false
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
			if navigation.mainToTwinOnboarding {
				navigation.mainToTwinOnboarding = false
			} else if !isFromMain {
				navigation.twinOnboardingToMain = true
			}
			userPrefsService.isTwinCardOnboardingWasDisplayed = true
		case .warning:
            if #available(iOS 14.0, *) {
                self.navigation.twinOnboardingToTwinWalletCreation = true
            } else {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    //fix navbar blink on ios 13
                    self.navigation.twinOnboardingToTwinWalletCreation = true
                }
            }
		}
	}
	
}
