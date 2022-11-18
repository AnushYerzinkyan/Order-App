//
//  Order.swift
//  Order App
//
//  Created by Anush Yerzinkyan on 30.10.22.
//

import Foundation

struct Order: Codable {
    var menuItems: [MenuItem]

    init(menuItems: [MenuItem] = []) {
        self.menuItems = menuItems
    }
}
