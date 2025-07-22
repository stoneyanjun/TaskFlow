//
//  Binding+Extension.swift
//  TaskFlowiOS
//
//  Created by stone on 2025/7/21.
//

import SwiftUI

// Binding extensions to allow editing optionals in SwiftUI
extension Binding {
    init(_ source: Binding<Value?>, replacingNilWith defaultValue: Value) {
        self.init(get: {
            source.wrappedValue ?? defaultValue
        }, set: {
            source.wrappedValue = $0
        })
    }
}
