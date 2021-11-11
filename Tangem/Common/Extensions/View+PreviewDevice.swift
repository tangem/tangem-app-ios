//
//  View+PreviewDevice.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import SwiftUI

extension View {
    func previewGroup(devices: [PreviewDeviceType] = [.iPhone7, .iPhone8Plus, .iPhoneX, .iPhone12Pro, .iPhone12ProMax], withZoomed: Bool = true) -> some View {
        Group {
            ForEach(devices) {
                deviceForPreview($0)
                if withZoomed {
                    deviceForPreviewZoomed($0)
                }
            }
        }
    }
}

enum PreviewDeviceType: String, Identifiable, CaseIterable {
	var id: UUID { UUID() }
	
	case iPhone7 = "iPhone 7"
	case iPhone8Plus = "iPhone 8 Plus"
    case iPhoneX = "iPhone X"
	case iPhone12Mini = "iPhone 12 mini"
	case iPhone11Pro = "iPhone 11 Pro"
	case iPhone11ProMax = "iPhone 11 Pro Max"
	case iPhone12Pro = "iPhone 12 Pro"
	case iPhone12ProMax = "iPhone 12 Pro Max"
    
    var zoomedLayout: PreviewLayout {
        switch self {
        case .iPhone7: return .iphone7Zoomed
        case .iPhone11Pro: return .iphone11Pro
        case .iPhone11ProMax: return .iphone11ProMax
        case .iPhone12Mini: return .iphone11Pro
        case .iPhone12Pro: return .iphone11Pro
        case .iPhone12ProMax: return .iphone11ProMax
        case .iPhone8Plus: return .iphone8Plus
        case .iPhoneX: return .iphone11Pro
        }
    }
}


extension View {
	func deviceForPreview(_ type: PreviewDeviceType) -> some View {
		self
			.previewDevice(PreviewDevice(rawValue: type.rawValue))
			.previewDisplayName(type.rawValue)
			
	}
    
    func deviceForPreviewZoomed(_ type: PreviewDeviceType) -> some View {
        previewLayout(type.zoomedLayout)
            .previewDisplayName("\(type.rawValue) Zoomed")
        
    }
}

extension PreviewLayout {
    static var iphone7Zoomed: PreviewLayout {
        .fixed(width: 320, height: 568)
    }
    
    static var iphone11Pro: PreviewLayout {
        .fixed(width: 320, height: 693)
    }
    
    static var iphone11ProMax: PreviewLayout {
        .fixed(width: 375, height: 812)
    }
    
    static var iphone8Plus: PreviewLayout {
        .fixed(width: 375, height: 667)
    }
}
