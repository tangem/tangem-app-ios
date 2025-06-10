//
//  OrganizeTokensDragAndDropGesturePredicate.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI
import UIKit

struct OrganizeTokensDragAndDropGesturePredicate: DragAndDropGesturePredicate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        for uiView in OrganizeTokensDragAndDropGestureMarkView.allInstances {
            let localPoint = touch.location(in: uiView)
            if uiView.bounds.contains(localPoint) {
                return true
            }
        }

        return false
    }
}
