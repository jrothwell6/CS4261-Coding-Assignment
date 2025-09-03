//
//  ContentView.swift
//  CS4261CodingAssignment
//
//  Created by Jeff Rothwell on 9/2/25.
//

import SwiftUI

// MARK: - Weather Models
struct WeatherResponse: Codable {
    let list: [Forecast]
}

struct Forecast: Codable {
    let dt_txt: String
    let main: Main
    let weather: [Weather]
}

struct Main: Codable {
    let temp: Double
}

struct Weather: Codable {
    let description: String
}

// MARK: - ContentView
struct ContentView: View {
    @State private var city: String = ""
    @State private var forecasts: [Forecast] = []
    @State private var errorMessage: String?

    var body: some View {
        NavigationView {
            VStack(spacing: 16) {
                TextField("Enter city name", text: $city)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.horizontal)

                Button("Fetch Weather") {
                    fetchWeather(for: city) { result in
                        switch result {
                        case .success(let response):
                            forecasts = response.list
                            errorMessage = nil
                        case .failure(let error):
                            forecasts = []
                            errorMessage = error.localizedDescription
                        }
                    }
                }
                .padding()

                if let error = errorMessage {
                    Text("Error: \(error)")
                        .foregroundColor(.red)
                        .padding(.horizontal)
                }

                List(forecasts, id: \.dt_txt) { forecast in
                    VStack(alignment: .leading) {
                        Text(forecast.dt_txt)
                            .font(.headline)
                        Text("\(forecast.main.temp, specifier: "%.1f")°C")
                        Text(forecast.weather.first?.description.capitalized ?? "")
                            .foregroundColor(.gray)
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle("Weather Peek")
        }
    }
}

// MARK: - API Call
func fetchWeather(for city: String, completion: @escaping (Result<WeatherResponse, Error>) -> Void) {
    let apiKey = "84f64074eb0b9937e9c46643694b0c0d" 
    let urlString = "https://api.openweathermap.org/data/2.5/forecast?q=\(city)&appid=\(apiKey)&units=metric"

    guard let url = URL(string: urlString) else {
        completion(.failure(NSError(domain: "Invalid URL", code: 0)))
        return
    }

    URLSession.shared.dataTask(with: url) { data, response, error in
        if let error = error {
            completion(.failure(error))
            return
        }

        guard let data = data else {
            completion(.failure(NSError(domain: "No data", code: 0)))
            return
        }

        do {
            let decoded = try JSONDecoder().decode(WeatherResponse.self, from: data)
            DispatchQueue.main.async {
                completion(.success(decoded))
            }
        } catch {
            completion(.failure(error))
        }
    }.resume()
}

#Preview {
    ContentView()
}
