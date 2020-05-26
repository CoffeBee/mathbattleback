//
//  Task.swift
//  Application
//
//  Created by Podvorniy Ivan on 26.05.2020.
//

import LoggerAPI
import KituraContracts


struct Task: Codable {
    let id: Int
    let title: String
    let text: String

    init(id: Int, title: String, text: String) {
        self.id = id
        self.title = title
        self.text = text
    }
}

