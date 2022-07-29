//
//  MainViewModel.swift
//  TangemClip
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import SwiftUI
import TangemSdk

class MainViewModel: ObservableObject {
    @Injected(\.tangemSdkProvider) var sdkProvider: TangemSdkProviding
    @Injected(\.cardImageLoader) var imageLoader: CardImageLoaderProtocol

    @Published var isScanning: Bool = false
    @Published var image: UIImage? = nil
    @Published var shouldShowGetFullApp = false

    private var imageLoadingCancellable: AnyCancellable?
    private var bag: Set<AnyCancellable> = []
    private var savedBatch: String?

    init() {
        updateCardBatch(nil, fullLink: "")
    }

    func updateCardBatch(_ batch: String?, fullLink: String) {
        savedBatch = batch
        //  shouldShowGetFullApp = false
        loadImageByBatch(batch, fullLink: fullLink)
    }

    func onAppear() {
        DispatchQueue.main.async {
            self.shouldShowGetFullApp = true
        }
    }

    private func loadImageByBatch(_ batch: String?, fullLink: String) {
        guard let _ = batch, !fullLink.isEmpty else {
            image = nil
            return
        }

        imageLoadingCancellable = imageLoader
            .loadImage(byNdefLink: fullLink)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { completion in
                print(completion)
            }, receiveValue: { [weak self] image in
                withAnimation {
                    self?.image = image
                }
            })
    }
}
