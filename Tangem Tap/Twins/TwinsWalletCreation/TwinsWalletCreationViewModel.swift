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
	
	enum Step: Comparable {
		case first, second, third
		
		var stepTitle: LocalizedStringKey {
			switch self {
			case .first: return "twin_wallet_creation_step_title_first"
			case .second: return "twin_wallet_creation_step_title_second"
			case .third: return "twin_wallet_creation_step_title_third"
			}
		}
		
		var title: LocalizedStringKey {
			switch self {
			case .first, .third: return "twin_wallet_creation_title_tap_first_twin"
			case .second: return "twin_wallet_creation_title_tap_second_twin"
			}
		}
		
		var hint: LocalizedStringKey {
			"twin_wallet_creation_hint"
		}
		
		var buttonTitle: LocalizedStringKey {
			switch self {
			case .first, .third: return "twin_wallet_creation_tap_first_card"
			case .second: return "twin_wallet_creation_tap_second_card"
			}
		}
		
		func nextStep() -> Step {
			switch self {
			case .first: return .second
			case .second: return .third
			case .third: return .first
			}
		}
	}
	
	@Published var navigation: NavigationCoordinator!
	@Published var step: Step = .first
	
	weak var assembly: Assembly!
	
	let isRecreatingWallet: Bool
	
	init(isRecreatingWallet: Bool) {
		self.isRecreatingWallet = isRecreatingWallet
	}
	
	func buttonAction() {
		switch step {
		case .first:
			firstStepScan()
		case .second:
			secondStepScan()
		case .third:
			thirdStepScan()
		}
		step = step.nextStep()
	}
	
	private func firstStepScan() {
	}
	
	private func secondStepScan() {
	}
	
	private func thirdStepScan() {
	}
	
	private func done() {
	}
	
}
