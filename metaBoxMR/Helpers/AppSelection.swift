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
    let appView: AnyView
    let appClass: AppClass
}

let metaBoxApps: [FunctionModel] = [
    FunctionModel(
        name: "合言葉Box",
        appView: AnyView(SesameBoxView()),
        appClass: SesameBox.shared
    ),
    FunctionModel(
        name: "宝箱Box",
        appView: AnyView(TreasureBoxView()),
        appClass: TreasureBox.shared
    ),
    FunctionModel(
        name: "タイマーBox",
        appView: AnyView(TimerBoxView()),
        appClass: TimerBox.shared
    ),
    FunctionModel(
        name: "フリマBox",
        appView: AnyView(FleaMarketBoxView()),
        appClass: FleaMarketBox.shared
    ),
]
