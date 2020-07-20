//
//  Extension+URL.swift
//  Fast Playist Maker
//
//

import Foundation

extension URL {
    
    func queryItemValueFor (key: String) -> String? {
        guard
            let components = URLComponents(url: self, resolvingAgainstBaseURL: false),
            let queryItems = components.queryItems
            else {
                return nil
        }
        
        return queryItems.first(where: { $0.name == key })?.value
    }
    
}

