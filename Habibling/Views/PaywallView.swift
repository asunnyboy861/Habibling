import SwiftUI
import StoreKit

struct PaywallView: View {
    @EnvironmentObject private var purchases: PurchaseManager
    @Environment(\.dismiss) private var dismiss

    @State private var purchasingPlus = false
    @State private var purchasingCloud = false
    @State private var message: String?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    PixelPetView(stage: .adult, mood: .joyful)
                        .frame(width: 110, height: 110)
                        .padding(.top, 8)
                    Text("Habibling Plus")
                        .font(.system(.title, design: .monospaced))
                        .fontWeight(.bold)
                    featureList
                    plusCard
                    cloudCard
                    restoreButton
                    legalFooter
                }
                .padding(20)
            }
            .background(AppTheme.page)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .onAppear {
                Task { await purchases.loadProducts() }
            }
        }
    }

    private var featureList: some View {
        VStack(alignment: .leading, spacing: 10) {
            featureRow(icon: "crown.fill", text: "JSON & CSV backup export and import")
            featureRow(icon: "icloud.fill", text: "iCloud sync is always free — no account needed")
            featureRow(icon: "sparkles", text: "Cloud AI reports that work even without Apple Intelligence")
            featureRow(icon: "heart.fill", text: "Your pet never dies. One-time purchase, forever yours")
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .pixelCard()
    }

    private func featureRow(icon: String, text: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: icon)
                .foregroundStyle(AppTheme.accent)
                .frame(width: 22)
            Text(text)
                .font(.subheadline)
        }
    }

    private var plusCard: some View {
        VStack(spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Habibling Plus")
                        .font(AppTheme.pixelTitle)
                    Text("One-time purchase. Yours forever.")
                        .font(AppTheme.pixelCaption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Text(priceText(for: purchases.plusProduct, fallback: "$24.99"))
                    .font(.system(.title3, design: .monospaced))
                    .fontWeight(.bold)
            }
            Button {
                Task { await buy(purchases.plusProduct, flag: $purchasingPlus) }
            } label: {
                if purchasingPlus {
                    ProgressView().frame(maxWidth: .infinity)
                } else {
                    Text(purchases.isPlus ? "Owned" : "Buy Plus").frame(maxWidth: .infinity)
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(purchasingPlus || purchases.isPlus)
        }
        .pixelCard()
    }

    private var cloudCard: some View {
        VStack(spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Habibling Cloud+")
                        .font(AppTheme.pixelTitle)
                    Text("Monthly AI boost, cancel anytime.")
                        .font(AppTheme.pixelCaption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Text(priceText(for: purchases.cloudProduct, fallback: "$1.99/mo"))
                    .font(.system(.title3, design: .monospaced))
                    .fontWeight(.bold)
            }
            Button {
                Task { await buy(purchases.cloudProduct, flag: $purchasingCloud) }
            } label: {
                if purchasingCloud {
                    ProgressView().frame(maxWidth: .infinity)
                } else {
                    Text(purchases.isCloudPlus ? "Subscribed" : "Subscribe").frame(maxWidth: .infinity)
                }
            }
            .buttonStyle(.bordered)
            .disabled(purchasingCloud || purchases.isCloudPlus)
        }
        .pixelCard()
    }

    private var restoreButton: some View {
        Button("Restore purchases") {
            Task {
                await purchases.restorePurchases()
                message = purchases.loadError ?? nil
            }
        }
        .font(.subheadline)
    }

    private var legalFooter: some View {
        VStack(spacing: 10) {
            HStack(spacing: 18) {
                Link("Privacy Policy", destination: URL(string: "https://asunnyboy861.github.io/Habibling/privacy.html")!)
                    .font(AppTheme.pixelCaption)
                Link("Terms of Use", destination: URL(string: "https://asunnyboy861.github.io/Habibling/terms.html")!)
                    .font(AppTheme.pixelCaption)
            }
            Text("Cloud+ is an auto-renewing subscription. Payment is charged to your Apple ID account at confirmation of purchase. Subscription renews automatically unless canceled at least 24 hours before the end of the current period. Manage or cancel anytime in your App Store account settings.")
                .font(.caption2)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            if let message {
                Text(message)
                    .font(.caption)
                    .foregroundStyle(.orange)
            }
        }
    }

    private func priceText(for product: Product?, fallback: String) -> String {
        product?.displayPrice ?? fallback
    }

    private func buy(_ product: Product?, flag: Binding<Bool>) async {
        guard let product else {
            message = "Store products are still loading. Try again in a moment."
            return
        }
        flag.wrappedValue = true
        let success = await purchases.purchase(product)
        flag.wrappedValue = false
        if success {
            Haptics.success()
            dismiss()
        } else if let error = purchases.loadError {
            message = error
        }
    }
}
