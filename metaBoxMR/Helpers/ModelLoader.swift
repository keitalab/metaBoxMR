//
//  ModelLoader.swift
//  metaBoxMR
//
//  Created by chiba yuto on 2025/02/28.
//

import Foundation
import RealityKit

@MainActor
final class ModelLoader {
    static let shared = ModelLoader()
    var loadModels: [String: ModelEntity] = [:]

    func loadAllUSDModels() async {
        // "usdz" と "usdc" のURLリストをそれぞれ取得。見つからなければ空の配列を返す
        let usdzURLs = Bundle.main.urls(forResourcesWithExtension: "usdz", subdirectory: nil) ?? []
        let usdcURLs = Bundle.main.urls(forResourcesWithExtension: "usdc", subdirectory: nil) ?? []
        
        // 両方を統合する
        let modelURLs = usdzURLs + usdcURLs
        
        if modelURLs.isEmpty {
            print("DEBUG!: No model found")
            return
        }

        // 拡張子が "usd" で始まるファイルをフィルタ
        let usdModelURLs = modelURLs.filter { url in
            let ext = url.pathExtension.lowercased()
            return ext.hasPrefix("usd")
        }

        // 各ファイルごとに非同期でモデルを読み込み
        for url in usdModelURLs {
            let modelName = url.deletingPathExtension().lastPathComponent
            do {
                let modelEntity = try await ModelEntity(contentsOf: url)
                loadModels[modelName] = modelEntity
                print("DEBUG!: Successfully loaded model \(modelName).")
            } catch {
                print("DEBUG!: Failed to load model \(modelName): \(error)")
            }
        }
    }
}
