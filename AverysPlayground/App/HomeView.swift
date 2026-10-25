import SwiftUI

struct HomeView: View {
    private let columns = [GridItem(.adaptive(minimum: 150), spacing: 20)]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    Text("Avery's Playground")
                        .font(.kid(40))
                        .foregroundStyle(.white)
                        .shadow(color: .black.opacity(0.2), radius: 2, y: 2)
                        .multilineTextAlignment(.center)
                        .padding(.top, 12)

                    LazyVGrid(columns: columns, spacing: 20) {
                        ForEach(Activity.allCases) { activity in
                            NavigationLink(value: activity) {
                                ActivityTile(activity: activity)
                            }
                            .buttonStyle(SquishyButtonStyle())
                            .simultaneousGesture(TapGesture().onEnded {
                                Speaker.shared.say(activity.title)
                            })
                        }
                    }
                }
                .padding(20)
            }
            .background(PlayfulBackground())
            .navigationDestination(for: Activity.self) { activity in
                activity.destination
                    .navigationTitle(activity.title)
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbarBackground(activity.color, for: .navigationBar)
                    .toolbarBackground(.visible, for: .navigationBar)
                    .toolbarColorScheme(.dark, for: .navigationBar)
            }
        }
        .tint(.white)
    }
}

private struct ActivityTile: View {
    let activity: Activity

    var body: some View {
        VStack(spacing: 8) {
            Text(activity.emoji)
                .font(.system(size: 64))
            Text(activity.title)
                .font(.kid(24))
                .foregroundStyle(.white)
        }
        .frame(maxWidth: .infinity, minHeight: 160)
        .background(activity.color.gradient, in: RoundedRectangle(cornerRadius: 32, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 32, style: .continuous)
                .strokeBorder(.white.opacity(0.6), lineWidth: 4)
        )
        .shadow(color: activity.color.opacity(0.5), radius: 8, y: 6)
    }
}

#Preview {
    HomeView()
}
