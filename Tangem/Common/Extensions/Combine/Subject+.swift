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
    var asReadWriteBinding: Binding<Output> {
        return Binding(
            get: { self.value },
            set: { self.send($0) }
        )
    }
}

extension Subject {
    func asWriteOnlyBinding(_ dummyValue: Output) -> Binding<Output> {
        return Binding(
            get: { dummyValue },
            set: { self.send($0) }
        )
    }
}

extension Subject where Output: ExpressibleByNilLiteral {
    var asWriteOnlyBinding: Binding<Output> { asWriteOnlyBinding(nil) }
}

extension Subject where Output: ExpressibleByIntegerLiteral {
    var asWriteOnlyBinding: Binding<Output> { asWriteOnlyBinding(0) }
}

extension Subject where Output: ExpressibleByFloatLiteral {
    var asWriteOnlyBinding: Binding<Output> { asWriteOnlyBinding(0.0) }
}
