//
//  NavigationButton.swift
//  Tangem Tap
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import SwiftUI

struct NavigationButton<Content: View, Navigation: View>: View {
	var button: Content
	var navigationLink: Navigation
	let indicatorSettings: IndicatorSettings
	
	init(button: Content, navigationLink: Navigation, indicatorSettings: IndicatorSettings = .default) {
		self.button = button
		self.navigationLink = navigationLink
		self.indicatorSettings = indicatorSettings
	}
	
	var body: some View {
		button
			.background(navigationLink)
	}
}
