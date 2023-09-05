//
//  Subject+.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import SwiftUI

extension CurrentValueSubject {
    var asBinding: Binding<Output> {
        return Binding(
            get: { self.value },
            set: { self.send($0) }
        )
    }
}

extension Subject {
    func asWriteOnlyBinding(_ defaultValue: Output) -> Binding<Output> {
        return Binding(
            get: { defaultValue },
            set: { self.send($0) }
        )
    }
}
