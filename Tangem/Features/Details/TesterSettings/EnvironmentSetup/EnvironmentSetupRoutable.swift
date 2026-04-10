//
//  EnvironmentSetupRoutable.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

protocol EnvironmentSetupRoutable: AnyObject {
    func openSupportedBlockchainsPreferences()
    func openStakingBlockchainsPreferences()
    func openNFTBlockchainsPreferences()
    func openAddressesInfo()
    func openDesignSystemDemo()
    func openSparrowSurveyClassicDemo(withToken token: String)
    func openSparrowSurveyChatDemo(withToken token: String)
    func openSparrowSurveyNPSDemo(withToken token: String)
}
