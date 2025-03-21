//
//  DragAndDropGestureContextProviding.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import UIKit

protocol DragAndDropGestureContextProviding {
    associatedtype Context

    func makeContext(from gestureRecognizer: UIGestureRecognizer) -> Context
}
