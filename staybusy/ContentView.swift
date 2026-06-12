//
//  ContentView.swift
//  staybusy
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        TodayView()
            .preferredColorScheme(.dark)
            .tint(Theme.accent)
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Block.self, inMemory: true)
}
