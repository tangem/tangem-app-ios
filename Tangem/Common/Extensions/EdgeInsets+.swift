//
// Copyright © 2023 m3g0byt3
//

import Foundation
import SwiftUI

extension EdgeInsets {
    init(horizontal: CGFloat, vertical: CGFloat = 0.0) {
        self.init(top: vertical, leading: horizontal, bottom: vertical, trailing: horizontal)
    }
}
