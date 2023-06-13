//
//  ActionButtonsProvider.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Combine

protocol ActionButtonsProvider: AnyObject {
    var buttonsPublisher: AnyPublisher<[ButtonWithIconInfo], Never> { get }
}
