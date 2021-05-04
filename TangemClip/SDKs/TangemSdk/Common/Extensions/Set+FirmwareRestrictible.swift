//
//  Set+FirmwareRestrictible.swift
//  TangemSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation

@available (iOS 13.0, *)
public protocol FirmwareRestictible {
    var minFirmwareVersion: FirmwareVersion { get }
    var maxFirmwareVersion: FirmwareVersion { get }
}


@available (iOS 13.0, *)
extension Set where Element: FirmwareRestictible {
	func minFirmwareVersion() -> FirmwareVersion {
		map { $0.minFirmwareVersion }.max() ?? .zero
	}
	
	func maxFirmwareVersion() -> FirmwareVersion {
		map { $0.maxFirmwareVersion }.min() ?? .zero
	}
}
