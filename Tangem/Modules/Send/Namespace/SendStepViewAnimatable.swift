//
//  SendStepViewAnimatable.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

protocol SendStepViewAnimatable {
    func viewDidChangeVisibilityState(_ state: SendStepVisibilityState)
}

enum SendStepVisibilityState: Hashable {
    case appearing(previousStep: SendStepType)
    case disappearing(nextStep: SendStepType)
}
