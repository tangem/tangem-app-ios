//
//  DisclaimerViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation

struct DisclaimerViewModel: Identifiable {
    let id: UUID = .init()

    let style: DisclaimerView.Style
    let showAccept: Bool
    var dismissCallback: () -> Void = {}
}
