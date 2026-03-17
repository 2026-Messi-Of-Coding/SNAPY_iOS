import Foundation

// MARK: - Request
/// POST /api/loan 요청 DTO (명세 키 이름 그대로)
struct LoanGuideRequestDTO: Codable {
    let age: Int
    let isHouseholder: Bool
    let familyType: String
    let annualSalary: Int
    let monthlySalary: Int
    let incomeType: String
    let incomeCategory: String
    let rentalArea: String
    let houseType: String
    let rentalType: String
    let deposit: Int
    let managementFee: Int
    let availableLoan: Bool
    let creditRating: Int
    let loanType: String
    let overdueRecord: Bool
    let hasLeaseAgreement: Bool
    /// 확정일자 여부 (RECEIVED, SCHEDULED, UNKNOWN)
    let confirmed: String

    static func from(_ data: LoanGuideData) -> LoanGuideRequestDTO {
        LoanGuideRequestDTO(
            age: data.age ?? 0,
            isHouseholder: data.isHeadOfHousehold ?? false,
            familyType: data.familyComposition?.apiValue ?? "SINGLE",
            annualSalary: data.annualIncome ?? 0,
            monthlySalary: data.monthlyIncome ?? 0,
            incomeType: data.incomeType?.apiValue ?? "EMPLOYEE",
            incomeCategory: data.incomeCategory?.apiValue ?? "EARNED_INCOME",
            rentalArea: data.rentalArea ?? "",
            houseType: data.houseType?.apiValue ?? "VILLA",
            rentalType: data.leaseType?.apiValue ?? "JEONSE",
            deposit: data.deposit ?? 0,
            managementFee: data.managementFee ?? 0,
            availableLoan: data.isLoanEligible ?? true,
            creditRating: data.creditRating?.numericValue ?? 5,
            loanType: data.loanType?.apiValue ?? "OTHER",
            overdueRecord: data.hasDelinquencyRecord ?? false,
            hasLeaseAgreement: data.hasLeaseAgreement ?? false,
            confirmed: data.fixedDateStatus?.apiValue ?? "UNKNOWN"
        )
    }
}

// MARK: - Response
struct LoanGuideResponseDTO: Codable {
    let loanAmount: Int
    let interestRate: Double
    let ownCapital: Int
    let monthlyInterest: Int
    let managementFee: Int
    let totalMonthlyCost: Int
    let loans: [LoanGuideBlockDTO]
    let procedures: [LoanGuideBlockDTO]
    let channels: [LoanGuideBlockDTO]
    let advance: [LoanGuideBlockDTO]
}

struct LoanGuideBlockDTO: Codable {
    let title: String
    let content: String
}

// MARK: - Enum mappings (UI rawValue와 분리)
private extension FamilyComposition {
    var apiValue: String {
        switch self {
        case .single:   return "SINGLE"
        // API 명세: HONEYMOON (신혼)
        case .newlywed: return "HONEYMOON"
        case .couple:   return "COUPLE"
        case .youth:    return "YOUTH"
        }
    }
}

private extension IncomeType {
    var apiValue: String {
        switch self {
        case .employee:     return "EMPLOYEE"
        case .freelancer:   return "FREELANCER"
        case .selfEmployed: return "SELF_EMPLOYED"
        }
    }
}

private extension IncomeCategory {
    var apiValue: String {
        switch self {
        // API 명세: EARNED_INCOME / BUSINESS_INCOME / OTHER_INCOME
        case .earned:   return "EARNED_INCOME"
        case .business: return "BUSINESS_INCOME"
        case .other:    return "OTHER_INCOME"
        }
    }
}

private extension HouseType {
    var apiValue: String {
        switch self {
        case .apartment: return "APARTMENT"
        case .officetel: return "OFFICETEL"
        case .villa:     return "VILLA"
        }
    }
}

private extension LoanGuideLeaseType {
    var apiValue: String {
        switch self {
        case .jeonse:  return "JEONSE"
        case .monthly: return "MONTHLY_RENT"
        }
    }
}

private extension CreditRating {
    var numericValue: Int {
        // "1등급" ~ "10등급"
        let digits = rawValue.filter(\.isNumber)
        return Int(digits) ?? 5
    }
}

private extension LoanType {
    var apiValue: String {
        switch self {
        case .credit:   return "CREDIT"
        case .jeonse:   return "JEONSE"
        case .mortgage: return "MORTGAGE"
        case .other:    return "OTHER"
        }
    }
}

private extension FixedDateStatus {
    var apiValue: String {
        switch self {
        case .received: return "RECEIVED"
        case .planned:  return "SCHEDULED"
        case .unknown:  return "UNKNOWN"
        }
    }
}


