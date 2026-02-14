//
//  StepsFlowStep.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI

public protocol StepsFlowStep: AnyObject {
    var id: AnyHashable { get }
    func makeView() -> any View
}
