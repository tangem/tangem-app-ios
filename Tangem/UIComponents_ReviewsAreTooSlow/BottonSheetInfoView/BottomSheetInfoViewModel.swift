//
//  BottomSheetInfoViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

public struct BottomSheetInfoViewModel: Identifiable {
    public struct Input {
        let icon: ImageType
        let title: String
        let description: String?
        let buttonTitle: String?
    }

    // MARK: - Properties

    public let id: UUID = .init()

    private let input: Input
    public let buttonTapAction: (() -> Void)?

    // MARK: - Init

    public init(input: Input, buttonTapAction: (() -> Void)?) {
        self.input = input
        self.buttonTapAction = buttonTapAction
    }

    // MARK: - Access

    public var icon: ImageType {
        input.icon
    }

    public var title: String {
        input.title
    }

    public var description: String? {
        input.description
    }

    public var buttonTitle: String? {
        input.buttonTitle
    }
}
