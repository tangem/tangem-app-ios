//
//  BottomSheetViewController.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI

class BottomSheetViewController<Content: View>: BottomSheetBaseController {
    @Binding private var isPresented: Bool

    private let contentView: UIHostingController<Content>

    init(isPresented: Binding<Bool>,
         content: Content) {
        _isPresented = isPresented
        self.contentView = UIHostingController(rootView: content)
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        #warning("[REDACTED_TODO_COMMENT]")
//        view.backgroundColor = .white
        view.layer.masksToBounds = true

        addChild(contentView)
        view.addSubview(contentView.view)

        contentView.view.translatesAutoresizingMaskIntoConstraints = false
        #warning("[REDACTED_TODO_COMMENT]")
        contentView.view.backgroundColor = UIColor(white: 0.96, alpha: 1)

        NSLayoutConstraint.activate([
            contentView.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            contentView.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            contentView.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            contentView.view.topAnchor.constraint(equalTo: view.topAnchor),
        ])
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        isPresented = false
    }
}
