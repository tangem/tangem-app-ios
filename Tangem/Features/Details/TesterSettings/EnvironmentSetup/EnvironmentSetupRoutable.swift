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
    #if INTERNAL || DEBUG
    func openDesignSystemDemo()
    #endif
    func openStoriesV2Demo()
    func openSparrowSurveyClassicDemo(withToken token: String)
    func openSilentPushTester()
}
