//
//  TransactionHistoryAuxDataRepositoryDependentTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Testing

/// Groups the suites that swap the process-global `transactionHistoryAuxDataRepository` for a stub. `.serialized` on
/// each of them orders only its own tests, so sibling suites could still overlap and read or restore each other's stub;
/// on a parent suite the trait applies to every nested one.
@Suite(.serialized)
enum TransactionHistoryAuxDataRepositoryDependentTests {}
