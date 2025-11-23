//
  //  ContentView.swift
  //  WidgetDebugger
  //

  import SwiftUI

  struct ContentView: View {
      @State private var currentEntry: TimetableEntry = TimetableEntry.example
      @State private var allEntries: [TimetableEntry] = []
      @State private var lastRefreshTime = Date()
      @State private var isRefreshing = false
      @State private var autoRefreshEnabled = false
      @State private var refreshInterval: TimeInterval = 60
      @State private var refreshCount = 0
      @State private var timer: Timer?

      var body: some View {
          NavigationView {
              ScrollView {
                  VStack(spacing: 20) {
                      controlsSection
                      statsSection
                      widgetPreviewsSection
                      timelineEntriesSection
                  }
                  .padding()
              }
              .navigationTitle("Widget Debugger")
              .navigationBarTitleDisplayMode(.inline)
              .onAppear {
                  refreshTimeline()
              }
              .onDisappear {
                  stopAutoRefresh()
              }
          }
      }

      // MARK: - View Sections

      private var controlsSection: some View {
          VStack(spacing: 12) {
              Button(action: { refreshTimeline() }) {
                  HStack {
                      Image(systemName: isRefreshing ? "arrow.clockwise.circle.fill" :
  "arrow.clockwise")
                      Text(isRefreshing ? "Refreshing..." : "Refresh Timeline")
                  }
                  .frame(maxWidth: .infinity)
                  .padding()
                  .background(Color.accentColor)
                  .foregroundColor(.white)
                  .cornerRadius(10)
              }
              .disabled(isRefreshing)

              Toggle("Auto-refresh", isOn: $autoRefreshEnabled)
                  .onChange(of: autoRefreshEnabled) { _, newValue in
                      if newValue {
                          startAutoRefresh()
                      } else {
                          stopAutoRefresh()
                      }
                  }

              if autoRefreshEnabled {
                  Picker("Interval", selection: $refreshInterval) {
                      Text("15 sec").tag(15.0)
                      Text("30 sec").tag(30.0)
                      Text("1 min").tag(60.0)
                      Text("2 min").tag(120.0)
                      Text("5 min").tag(300.0)
                  }
                  .pickerStyle(.segmented)
                  .onChange(of: refreshInterval) { _, _ in
                      if autoRefreshEnabled {
                          stopAutoRefresh()
                          startAutoRefresh()
                      }
                  }
              }
          }
          .padding()
          .background(Color(.systemGroupedBackground))
          .cornerRadius(12)
      }

      private var statsSection: some View {
          VStack(spacing: 8) {
              statRow("Last Refresh:", formatTime(lastRefreshTime))
              statRow("Refresh Count:", "\(refreshCount)")
              statRow("Timeline Entries:", "\(allEntries.count)")
              statRow("Entry State:", stateDescription(currentEntry.state))
              statRow("Memory Usage:", formatMemoryUsage())
          }
          .font(.system(.body, design: .monospaced))
          .padding()
          .background(Color(.systemGroupedBackground))
          .cornerRadius(12)
      }

      private func statRow(_ label: String, _ value: String) -> some View {
          HStack {
              Text(label)
              Spacer()
              Text(value)
                  .foregroundColor(.secondary)
          }
      }

      private var widgetPreviewsSection: some View {
          VStack(spacing: 16) {
              Text("Widget Previews")
                  .font(.headline)
                  .frame(maxWidth: .infinity, alignment: .leading)

              VStack(alignment: .leading, spacing: 8) {
                  Text("Lock Screen (Rectangular)")
                      .font(.caption)
                      .foregroundColor(.secondary)

                  RectangularWidgetView(entry: currentEntry)
                      .frame(height: 100)
                      .background(Color.black)
                      .cornerRadius(12)
              }

              VStack(alignment: .leading, spacing: 8) {
                  Text("Home Screen (Small)")
                      .font(.caption)
                      .foregroundColor(.secondary)

                  SystemSmallWidgetView(entry: currentEntry)
                      .frame(width: 150, height: 150)
                      .background(Color(.systemBackground))
                      .cornerRadius(12)
                      .shadow(radius: 2)
              }

              VStack(alignment: .leading, spacing: 8) {
                  Text("Inline")
                      .font(.caption)
                      .foregroundColor(.secondary)

                  HStack {
                      InlineWidgetView(entry: currentEntry)
                      Spacer()
                  }
                  .padding()
                  .background(Color(.systemGroupedBackground))
                  .cornerRadius(8)
              }
          }
      }

      private var timelineEntriesSection: some View {
          VStack(alignment: .leading, spacing: 12) {
              Text("Timeline Entries (\(allEntries.count))")
                  .font(.headline)

              if allEntries.isEmpty {
                  Text("No entries generated")
                      .foregroundColor(.secondary)
                      .padding()
              } else {
                  ForEach(Array(allEntries.enumerated()), id: \.offset) { index, entry in
                      entryCard(index: index, entry: entry)
                  }
              }
          }
      }

      private func entryCard(index: Int, entry: TimetableEntry) -> some View {
          VStack(alignment: .leading, spacing: 4) {
              HStack {
                  Text("Entry \(index + 1)")
                      .font(.subheadline.bold())
                  if index == 0 {
                      Text("CURRENT")
                          .font(.caption)
                          .padding(.horizontal, 6)
                          .padding(.vertical, 2)
                          .background(Color.accentColor)
                          .foregroundColor(.white)
                          .cornerRadius(4)
                  }
                  Spacer()
              }

              Text("Date: \(formatTime(entry.date))")
                  .font(.caption)
                  .foregroundColor(.secondary)

              Text("Stop: \(entry.stopName)")
                  .font(.caption)

              Text("Departures: \(entry.departures.count)")
                  .font(.caption)

              if !entry.departures.isEmpty {
                  ForEach(entry.departures.prefix(3), id: \.routeShortName) { dep in
                      HStack(spacing: 8) {
                          Text(dep.routeShortName)
                              .font(.caption.bold())
                          Text(dep.headsign)
                              .font(.caption)
                          Spacer()
                          Text(formatTime(dep.departureTime))
                              .font(.caption)
                              .foregroundColor(.secondary)
                      }
                      .padding(.leading, 12)
                  }
              }
          }
          .padding()
          .background(Color(.systemGroupedBackground))
          .cornerRadius(8)
      }

      // MARK: - Timeline Logic

      private func refreshTimeline() {
          isRefreshing = true
          refreshCount += 1
          lastRefreshTime = Date()

          let timelineBuilder = TimelineBuilder()
          timelineBuilder.buildTimeline(now: Date(), maxShown: 2) { timeline in
              DispatchQueue.main.async {
                  self.allEntries = timeline.entries
                  if let first = timeline.entries.first {
                      self.currentEntry = first
                  }
                  self.isRefreshing = false
              }
          }
      }

      private func startAutoRefresh() {
          stopAutoRefresh()
          timer = Timer.scheduledTimer(withTimeInterval: refreshInterval, repeats: true) { _ in
              refreshTimeline()
          }
      }

      private func stopAutoRefresh() {
          timer?.invalidate()
          timer = nil
      }

      // MARK: - Formatters

      private func formatTime(_ date: Date) -> String {
          let formatter = DateFormatter()
          formatter.dateFormat = "HH:mm:ss"
          return formatter.string(from: date)
      }

      private func stateDescription(_ state: TimetableEntry.WidgetState) -> String {
          switch state {
          case .normal: return "Normal"
          case .noFavorites: return "No Favorites"
          case .noDepartures: return "No Departures"
          }
      }

      private func formatMemoryUsage() -> String {
          var info = mach_task_basic_info()
          var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size) / 4

          let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
              $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                  task_info(mach_task_self_,
                           task_flavor_t(MACH_TASK_BASIC_INFO),
                           $0,
                           &count)
              }
          }

          if kerr == KERN_SUCCESS {
              let usedMB = Double(info.resident_size) / 1024.0 / 1024.0
              return String(format: "%.1f MB", usedMB)
          } else {
              return "N/A"
          }
      }
  }

  #Preview {
      ContentView()
  }
