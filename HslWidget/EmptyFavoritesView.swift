//
//  EmptyFavoritesView.swift
//  HslWidget
//
//  Empty state shown when no favorites are selected
//

import SwiftUI

struct EmptyFavoritesView: View {
    let onAddStop: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "star.slash")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            Text("No favorite stops selected")
                .font(.title2)
                .foregroundColor(.secondary)
            Text("Tap the button below to select your favorite stops")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Button(action: onAddStop) {
                Label("Add Favorite Stop", systemImage: "plus.circle.fill")
                    .font(.headline)
                    .padding()
                    .background(Color.accentColor)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .padding(.top, 8)
        }
        .frame(maxHeight: .infinity)
    }
}

#Preview {
    EmptyFavoritesView(onAddStop: {})
}
