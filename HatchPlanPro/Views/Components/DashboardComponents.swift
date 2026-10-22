import SwiftUI

struct MetricCardView: View {
    let title: String
    let value: String
    let change: String
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(title)
                    .font(.footnote.weight(.medium))
                    .foregroundColor(.secondary)
                Spacer()
                Circle()
                    .fill(tint.opacity(0.18))
                    .frame(width: 12, height: 12)
            }

            Text(value)
                .font(.title2.bold())
                .foregroundColor(.figmaTextDark)

            Text(change)
                .font(.footnote.weight(.semibold))
                .foregroundColor(tint)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 22, style: .continuous).fill(.white))
        .shadow(color: .black.opacity(0.05), radius: 12, x: 0, y: 6)
    }
}

struct BatchRowView: View {
    let name: String
    let stage: String
    let eggs: Int
    let temperature: Double
    let humidity: Double
    let isCritical: Bool
    let progress: Double
    let turnerStatus: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: isCritical ? "exclamationmark.triangle.fill" : "shippingbox.fill")
                .foregroundColor(isCritical ? .red : .figmaPrimary)
                .frame(width: 42, height: 42)
                .background(Circle().fill((isCritical ? Color.red : Color.figmaPrimary).opacity(0.12)))

            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(name)
                        .font(.headline)
                        .foregroundColor(.figmaTextDark)
                    Spacer()
                    Text(stage)
                        .font(.caption.weight(.semibold))
                        .foregroundColor(isCritical ? .red : .secondary)
                }
                Text("\(eggs) eggs • \(turnerStatus)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                ProgressView(value: progress)
                    .tint(isCritical ? .red : .figmaPrimary)
                HStack {
                    Text("Temp \(temperature, specifier: "%.1f")°C")
                    Spacer()
                    Text("Humidity \(humidity, specifier: "%.0f")%")
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 20, style: .continuous).fill(Color.figmaBackground))
    }
}

struct TaskRowView: View {
    let title: String
    let subtitle: String
    let isDone: Bool
    let dueLabel: String
    let iconName: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: iconName)
                .foregroundColor(.white)
                .frame(width: 38, height: 38)
                .background(Circle().fill(isDone ? Color(hex: "#14796D") : Color.figmaPrimary))

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.figmaTextDark)
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Text(dueLabel)
                .font(.caption.weight(.semibold))
                .foregroundColor(isDone ? .green : .secondary)
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 20, style: .continuous).fill(Color.figmaBackground))
    }
}

struct AlertCardView: View {
    let title: String
    let details: String
    let severity: String
    let timeLabel: String
    let iconName: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: iconName)
                .foregroundColor(severity == "Critical" ? .red : .figmaPrimary)
                .frame(width: 38, height: 38)
                .background(Circle().fill((severity == "Critical" ? Color.red : Color.figmaPrimary).opacity(0.12)))

            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(.figmaTextDark)
                    Spacer()
                    Text(timeLabel)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Text(details)
                    .foregroundColor(.secondary)
                    .font(.subheadline)
                Text(severity)
                    .font(.caption.weight(.semibold))
                    .foregroundColor(severity == "Critical" ? .red : .figmaPrimary)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 24, style: .continuous).fill(.white))
        .shadow(color: .black.opacity(0.05), radius: 12, x: 0, y: 6)
    }
}
