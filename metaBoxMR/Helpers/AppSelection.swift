//
//  AppSelection.swift
//  metaBoxMR
//
//  Created by chiba yuto on 2024/10/28.
//

import SwiftUI

struct FunctionModel: Identifiable {
    let id = UUID()
    let name: String
    let action: () -> AnyView
}

let metaBoxApps: [FunctionModel] = [
    FunctionModel(name: "タイマーBox", action: {
        AnyView(TimerBoxView())
    }),
    FunctionModel(name: "合言葉Box", action: {
        AnyView(SesameBoxView())
    }),
    FunctionModel(name: "PayBox", action: {
        AnyView(PayBoxView())
    })
]
