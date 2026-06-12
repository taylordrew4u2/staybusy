//
//  ContentView.swift
//  staybusy
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "checklist")
                .font(.system(size: 56))
                .foregroundStyle(.tint)
            Text("StayBusy")
                .font(.largeTitle.bold())
            Text("Get started building your app.")
                .foregroundStyle(.secondary)
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
