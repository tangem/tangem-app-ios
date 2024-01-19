//
//  MainViewPage.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

// An interface representing single page (typically, one page per card or wallet) on the main screen.
protocol MainViewPage {
    func onPageAppear()
    func onPageDisappear()
}
