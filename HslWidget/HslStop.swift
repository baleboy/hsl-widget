//
//  Stop.swift
//  HslWidget
//
//  Created by Francesco Balestrieri on 5.5.2024.
//

import Foundation

class HslStop {
    
    struct Departure {
        let routeShortName: String
        let routeLongName: String
        let realtimeDepartureTime: Date
        let scheduledDepartureTime: Date
    }
    
    let stationId: Int
    var departures: [Departure]
    
    init(stationId: Int) {
        self.stationId = stationId
        departures = []
        // load departures
    }
    
    private func loadDepartures() -> [Departure] {
        var departures: [Departure] = []
                    
        let query = """
            {
                stop(id:\"HSL:\(stationId)\"){
                    name
                    stoptimesWithoutPatterns {
                        realtimeArrival
                        serviceDay
                        trip{
                          route {
                            shortName
                            longName
                          }
                        }
                    }
                }
            }
            """

            guard let url = URL(string: "https://api.digitransit.fi/routing/v1/routers/hsl/index/graphql?digitransit-subscription-key=" + HSL_API_KEY) else {
                    print("Invalid URL")
                    return
                }
            
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
                
            let requestBody = query
            
            print("Request Body: \(requestBody)")
            request.httpBody = requestBody.data(using: .utf8)

            request.setValue("application/graphql", forHTTPHeaderField: "Content-Type")

            let session = URLSession.shared
            
            let task = session.dataTask(with: request) { data, response, error in
                if let error = error {
                    print("Error: \(error)")
                    return
                }
                
                if let httpResponse = response as? HTTPURLResponse {
                    print("Status code: \(httpResponse.statusCode)")
                }
                
                if let data = data {
                    // Parse the JSON data into a GraphQLResponse struct
                    do {
                        let decoder = JSONDecoder()
                        let graphQLResponse = try decoder.decode(GraphQLResponse.self, from: data)
                        stopName = graphQLResponse.data.stop.name
                        routeShortName = graphQLResponse.data.stop.stoptimesWithoutPatterns.first?.trip.route.shortName ?? "No name"

                        routeLongName = graphQLResponse.data.stop.stoptimesWithoutPatterns.first?.trip.route.longName ?? "No name"

                        // Access the first stoptime
                        if let firstStoptime = graphQLResponse.data.stop.stoptimesWithoutPatterns.first {
                            // Combine serviceDay and realtimeArrival
                            let arrivalTimeStamp = firstStoptime.serviceDay + firstStoptime.realtimeArrival
                            print("Arrival Time Stamp: \(arrivalTimeStamp)")
                            // Convert timestamp to Date
                            let date = Date(timeIntervalSince1970: arrivalTimeStamp)
                            
                            // Create a date formatter
                            let dateFormatter = DateFormatter()
                            dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss" // Specify the format you desire
                            
                            // Format the date as a string
                            arrivalTimeText = dateFormatter.string(from: date)
                            
                            print("Arrival Time: \(arrivalTimeText)")
                        } else {
                            print("No stoptimes found")
                        }
                    } catch {
                        print("Error parsing JSON: \(error)")
                    }
                }
            }
            task.resume()
        }

        
        
        return departures
    }
    
    
}
