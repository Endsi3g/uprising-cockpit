import WidgetKit
import SwiftUI

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), savings: "$0.00")
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        let entry = SimpleEntry(date: Date(), savings: "$0.00")
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        // Le nom de groupe de l'App (App Group) doit être configuré dans Xcode
        let userDefaults = UserDefaults(suiteName: "group.UprisingCockpit")
        let savings = userDefaults?.string(forKey: "savings") ?? "$0.00"

        let entry = SimpleEntry(date: Date(), savings: savings)
        let timeline = Timeline(entries: [entry], policy: .atEnd)
        completion(timeline)
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let savings: String
}

struct UprisingCockpitWidgetEntryView : View {
    var entry: Provider.Entry

    var body: some View {
        VStack {
            Text("Revenus Sauvés")
                .font(.caption)
                .foregroundColor(.gray)
            Text(entry.savings)
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(Color(red: 26/255, green: 158/255, blue: 91/255))
        }
    }
}

@main
struct UprisingCockpitWidget: Widget {
    let kind: String = "UprisingCockpitWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            UprisingCockpitWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Cockpit Uprising")
        .description("Suit vos revenus sauvés aujourd'hui.")
        .supportedFamilies([.systemSmall])
    }
}
