//
//  TripTabView.swift
//  staybusy
//

import SwiftUI

struct TripTabView: View {
    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()

            VStack(spacing: 10) {
                Image(systemName: "suitcase")
                    .font(.system(size: 44, weight: .heavy))
                    .foregroundStyle(Theme.textSecondary)
                Text("Trip")
                    .font(.system(.title2, design: .rounded).weight(.heavy))
                    .foregroundStyle(Theme.textPrimary)
                Text("Coming soon")
                    .font(.system(.subheadline, design: .rounded).weight(.semibold))
                    .foregroundStyle(Theme.textSecondary)
            }
        }
        .preferredColorScheme(.dark)
    }
}

#Preview {
    TripTabView()
}
