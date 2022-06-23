//
//  CoordinatorView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI

protocol CoordinatorView: View {
    associatedtype CoordinatorType: ObservableObject

    var coordinator: CoordinatorType { get }
}
