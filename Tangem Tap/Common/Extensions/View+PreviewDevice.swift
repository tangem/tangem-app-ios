//
//  View+PreviewDevice.swift
//  Tangem Tap
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import SwiftUI

extension View {
    func previewGroup(devices: [PreviewDeviceType] = PreviewDeviceType.allCases) -> some View {
        Group {
            ForEach(devices) {
                self.deviceForPreview($0)
            }
        }
    }
}

enum PreviewDeviceType: String, Identifiable, CaseIterable {
	var id: UUID { UUID() }
	
	case iPhone7 = "iPhone 7"
	case iPhone8Plus = "iPhone 8 Plus"
	case iPhone12Mini = "iPhone 12 mini"
	case iPhone11Pro = "iPhone 11 Pro"
	case iPhone11ProMax = "iPhone 11 Pro Max"
	case iPhone12Pro = "iPhone 12 Pro"
	case iPhone12ProMax = "iPhone 12 Pro Max"
}

extension View {
	func deviceForPreview(_ type: PreviewDeviceType) -> some View {
		self
			.previewDevice(PreviewDevice(rawValue: type.rawValue))
			.previewDisplayName(type.rawValue)
			
	}
}
