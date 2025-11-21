//
//  ContentView.swift
//  IELTSPart2Coach
//
//  Created by Charlie on 2025-11-04.
//  Phase 7.1: Updated to inject ModelContext into DataManager
//

import SwiftUI
struct ContentView: View {
    var body: some View {
        QuestionCardView()
            // ✅ FIX: Removed all diagnostic timing and logging for faster startup
            // Phase 7.1.2: SwiftData disabled, no modelContext injection required
    }
}

#Preview {
    ContentView()
}
