//
//  Unlock.swift
//  metaBoxMR
//
//  Created by chiba yuto on 2024/10/25.
//

import SwiftUI

func unlock() {
//    let urlString: String = "http://172.20.10.4/open"
    let urlString: String = "http://192.168.100.150/open"
    guard let url = URL(string: urlString) else { return }
    
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    
    let task = URLSession.shared.dataTask(with: request) { data, response, error in
        guard let data else { return }
        do {
            let json = try JSONSerialization.jsonObject(with: data, options: [])
            print(json)
        } catch {
            print(error)
        }
    }
    
    task.resume()
}
