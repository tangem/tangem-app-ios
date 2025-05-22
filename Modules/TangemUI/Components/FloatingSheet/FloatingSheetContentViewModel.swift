//
//  FloatingSheetContentViewModel.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Combine
import SwiftUI

public protocol FloatingSheetContentViewModel: ObservableObject, Identifiable {
    var id: String { get }
}
