//
//  StopFilterView.swift
//  HslWidget
//
//  View for configuring line and headsign filters for a stop
//

import SwiftUI

struct StopFilterView: View {
    let stop: Stop
    let onSave: (Stop) -> Void
    let onDismiss: () -> Void

    @State private var availableLines: [String] = []
    @State private var selectedLines: Set<String> = []
    @State private var headsignPattern: String = ""
    @State private var isLoadingLines = true
    @State private var showAllLines = true // If true, show all lines (no filter)

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Stop Information")) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(stop.name)
                            .font(.roundedHeadline)
                        Text(stop.code)
                            .font(.roundedCaption)
                            .foregroundColor(.secondary)
                    }
                }

                Section(header: Text("Filter by Lines"), footer: Text("Select specific lines to show, or show all lines from this stop")) {
                    if isLoadingLines {
                        HStack {
                            ProgressView()
                            Text("Loading available lines...")
                                .foregroundColor(.secondary)
                        }
                    } else if availableLines.isEmpty {
                        Text("No lines available")
                            .foregroundColor(.secondary)
                    } else {
                        Toggle("Show all lines", isOn: $showAllLines)
                            .onChange(of: showAllLines) { oldValue, newValue in
                                if newValue {
                                    selectedLines.removeAll()
                                }
                            }

                        if !showAllLines {
                            ForEach(availableLines, id: \.self) { line in
                                Button(action: {
                                    toggleLineSelection(line)
                                }) {
                                    HStack {
                                        Text(line)
                                            .foregroundColor(.primary)
                                        Spacer()
                                        if selectedLines.contains(line) {
                                            Image(systemName: "checkmark")
                                                .foregroundColor(.accentColor)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                Section(header: Text("Filter by Destination"), footer: Text("Only show departures whose destination contains this text (case insensitive)")) {
                    TextField("e.g., Kamppi, Keskusta", text: $headsignPattern)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                }

                Section {
                    HStack {
                        Spacer()
                        Text("Filters Active")
                            .font(.roundedCaption)
                            .foregroundColor(.secondary)
                        Image(systemName: hasActiveFilters ? "checkmark.circle.fill" : "xmark.circle")
                            .foregroundColor(hasActiveFilters ? .green : .secondary)
                        Spacer()
                    }
                }
            }
            .navigationTitle("Configure Filters")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        onDismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveFilters()
                    }
                }
            }
            .task {
                await loadAvailableLines()
                loadCurrentFilters()
            }
        }
    }

    private var hasActiveFilters: Bool {
        return (!showAllLines && !selectedLines.isEmpty) || !headsignPattern.trimmingCharacters(in: .whitespaces).isEmpty
    }

    private func toggleLineSelection(_ line: String) {
        if selectedLines.contains(line) {
            selectedLines.remove(line)
        } else {
            selectedLines.insert(line)
        }
    }

    private func loadCurrentFilters() {
        // Load existing filters from the stop
        if let filteredLines = stop.filteredLines, !filteredLines.isEmpty {
            selectedLines = Set(filteredLines)
            showAllLines = false
        } else {
            showAllLines = true
        }

        if let pattern = stop.filteredHeadsignPattern {
            headsignPattern = pattern
        }
    }

    private func loadAvailableLines() async {
        isLoadingLines = true

        // Fetch departures to get available lines
        let departures = await HslApi.shared.fetchDepartures(stationId: stop.id, numberOfResults: 50)

        // Extract unique route short names
        var uniqueLines = Set<String>()
        for departure in departures {
            uniqueLines.insert(departure.routeShortName)
        }

        let sortedLines = Array(uniqueLines).sorted()

        await MainActor.run {
            availableLines = sortedLines
            isLoadingLines = false
        }
    }

    private func saveFilters() {
        // Create updated stop with new filters
        let updatedStop = Stop(
            id: stop.id,
            name: stop.name,
            code: stop.code,
            latitude: stop.latitude,
            longitude: stop.longitude,
            vehicleModes: stop.vehicleModes,
            headsigns: stop.headsigns,
            allStopIds: stop.allStopIds,
            filteredLines: showAllLines ? nil : (selectedLines.isEmpty ? nil : Array(selectedLines).sorted()),
            filteredHeadsignPattern: headsignPattern.trimmingCharacters(in: .whitespaces).isEmpty ? nil : headsignPattern.trimmingCharacters(in: .whitespaces)
        )

        onSave(updatedStop)
    }
}

#Preview {
    StopFilterView(
        stop: Stop.defaultStop,
        onSave: { _ in },
        onDismiss: { }
    )
}
