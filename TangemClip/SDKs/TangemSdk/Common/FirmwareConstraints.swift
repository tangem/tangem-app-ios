//
//  FirmwareConstraints.swift
//  TangemSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation

public struct FirmwareConstraints {
	
    public struct AvailabilityVersions {
        public static let walletData = FirmwareVersion(major: 4, minor: 0)
        public static let pin2IsDefault = FirmwareVersion(major: 4, minor: 0)
        public static let files = FirmwareVersion(major: 3, minor: 29)
	}
	
    public struct DeprecationVersions {
        public static let walletRemainingSignatures = FirmwareVersion(major: 4, minor: 0)
	}
	
}
