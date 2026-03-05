//
//  StepsFlowStep.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI

public protocol StepsFlowStep {
    typealias Id = AnyHashable

    var id: Id { get }
    func makeView() -> any View
}
