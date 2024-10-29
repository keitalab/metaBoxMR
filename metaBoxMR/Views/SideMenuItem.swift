//
//  SideMenuItem.swift
//  metaBoxMR
//
//  Created by chiba yuto on 2024/10/29.
//

import Foundation

struct SideMenuItem: Identifiable, Hashable {
    var id = UUID()
    var name: String
    var icon: String
}

let sideMenuItems: [SideMenuItem] = [
    SideMenuItem(name: "Tracking", icon: "house"),
    SideMenuItem(name: "Menu", icon: "info"),
]
