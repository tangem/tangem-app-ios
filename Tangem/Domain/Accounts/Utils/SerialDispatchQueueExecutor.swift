//
//  SerialDispatchQueueExecutor.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

final class SerialDispatchQueueExecutor: SerialExecutor {
    private let workingQueue: DispatchQueue

    init(label: String) {
        workingQueue = DispatchQueue(
            label: "com.tangem.SerialDispatchQueueExecutor.workingQueue_\(label)",
            target: .global(qos: .userInitiated)
        )
    }

    func enqueue(_ job: UnownedJob) {
        let executor = asUnownedSerialExecutor()
        workingQueue.async {
            job.runSynchronously(on: executor)
        }
    }

    func asUnownedSerialExecutor() -> UnownedSerialExecutor {
        UnownedSerialExecutor(ordinary: self)
    }
}
