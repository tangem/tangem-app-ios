//
//  MainBottomSheetFooterViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import CombineExt
import class UIKit.UIImage

final class MainBottomSheetFooterViewModel: ObservableObject {
    @Published private(set) var snapshotImage: UIImage?

    @Injected(\.mainBottomSheetUIManager) private var mainBottomSheetUIManager: MainBottomSheetUIManager

    private var subscription: AnyCancellable?

    init() {
        bind()
    }

    private func bind() {
        guard subscription == nil else {
            return
        }

        subscription = mainBottomSheetUIManager
            .footerSnapshotPublisher
            .assign(to: \.snapshotImage, on: self, ownership: .weak)
    }
}
