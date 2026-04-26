import SwiftUI

struct DateRangeField: View {
    @Binding var startDate: Date
    @Binding var endDate: Date
    @State private var isPopoverPresented = false

    var body: some View {
        HStack(spacing: AppSpacing.sm) {
            Text(AppFormatters.editableDateText(startDate))
                .frame(width: 92)
                .multilineTextAlignment(.leading)

            Text("—")
                .foregroundStyle(AppColors.secondaryText)

            Text(AppFormatters.editableDateText(endDate))
                .frame(width: 92)
                .multilineTextAlignment(.leading)

            Button {
                isPopoverPresented.toggle()
            } label: {
                Image(systemName: "calendar")
                    .foregroundStyle(AppColors.secondaryText)
            }
            .buttonStyle(.plain)
            .popover(isPresented: $isPopoverPresented) {
                VStack(spacing: AppSpacing.md) {
                    DatePicker("С", selection: $startDate, displayedComponents: .date)
                    DatePicker("По", selection: $endDate, displayedComponents: .date)
                }
                .padding()
                .frame(width: 280)
            }
        }
        .font(.system(size: 14, weight: .semibold))
        .foregroundStyle(AppColors.primaryText)
        .padding(.horizontal, 14)
        .frame(height: 36)
        .background(AppColors.fieldFill, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .strokeBorder(AppColors.fieldBorder, lineWidth: 1)
        }
    }
}
