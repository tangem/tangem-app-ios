//
//  WalletConfig.swift
//  TangemSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation

/// Configuration for `CreateWalletCommand`. This config will override default settings saved on card
public struct WalletConfig {
	let isReusable: Bool?
	let prohibitPurgeWallet: Bool?
	let curveId: EllipticCurve?
	let signingMethods: SigningMethod?
	
	public init(isReusable: Bool? = nil, prohibitPurgeWallet: Bool? = nil, curveId: EllipticCurve? = nil, signingMethods: SigningMethod? = nil) {
		self.isReusable = isReusable
		self.prohibitPurgeWallet = prohibitPurgeWallet
		self.curveId = curveId
		self.signingMethods = signingMethods
	}
	
	var settingsMask: WalletSettingsMask? {
        guard isReusable != nil || prohibitPurgeWallet != nil else { return nil }
        
		let builder = WalletSettingsMaskBuilder()
		
        if isReusable ?? false {
			builder.add(.isReusable)
		}
		
		if prohibitPurgeWallet ?? false {
			builder.add(.prohibitPurgeWallet)
		}
		
		return builder.build()
	}
}
