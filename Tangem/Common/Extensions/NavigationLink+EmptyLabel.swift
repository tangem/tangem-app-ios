//
//  NavigationLink+EmptyLabel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import SwiftUI

extension NavigationLink where Label == EmptyView, Destination: View {
	
	init(destination: Destination, isActive: Binding<Bool>) {
		self.init(
			destination: destination,
			isActive: isActive,
			label: {
				EmptyView()
			})
	}

}
