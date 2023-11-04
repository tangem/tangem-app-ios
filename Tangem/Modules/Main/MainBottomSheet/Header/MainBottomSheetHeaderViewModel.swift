//
//  MainBottomSheetHeaderViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Combine

// [REDACTED_TODO_COMMENT]
// [REDACTED_TODO_COMMENT]
final class MainBottomSheetHeaderViewModel: ObservableObject {
    var enteredSearchTextPublisher: some Publisher<String, Never> { return $enteredSearchText }

    @Published var enteredSearchText: String = ""
}
