# FINALISED PRODUCT REQUIREMENTS DOCUMENT (PRD) - SLG-GOLDS

**Project Name:** SLG-GOLDS (Gold/Silver Investment Scheme Management)  
**Version:** 1.0.0  
**Status:** Production Ready  
**Date:** 2026-01-18

---

## 1. Executive Summary
SLG-GOLDS is an enterprise-grade digital platform designed for SLG Thangangal to automate and scale gold and silver investment scheme operations. The system replaces manual, paper-based processes with a unified technological framework, encompassing a Flutter mobile application for field operations and customer engagement, and a Next.js-based administrative portal for comprehensive business governance.

## 2. Project Overview
The project addresses critical bottlenecks in gold savings schemes, specifically manual payment collection, fragmented customer data, and lack of real-time financial visibility. By integrating field-agent mobility with centralized administration, SLG-GOLDS ensures operational efficiency, data integrity, and business scalability.

## 3. Scope Definition
- **In-Scope:** Customer KYC management, 18 Gold/Silver schemes, route-based staff assignment, field payment collection (offline sync), withdrawal requests, financial dashboards, and automated market rate integration.
- **Out-of-Scope (Phase 1):** Third-party payment gateway integration, advanced predictive analytics, multi-language support (English only), and customer self-enrollment (enrollment is office-controlled).

## 4. User Roles & Permissions
- **Administrator (Web):** Full system access, financial oversight, staff management, and scheme configuration.
- **Office Staff (Web):** Customer enrollment, route management, customer-to-staff assignment, and manual office collections.
- **Collection Staff (Mobile):** Field payment collection for assigned customers, daily target tracking, and performance viewing.
- **Customer (Mobile):** Portfolio tracking, payment history viewing, and withdrawal requests.

## 5. Functional Requirements
### Mobile Application
- **Authentication:** Phone/OTP + 6-digit PIN + Biometric.
- **Dashboard:** Real-time holdings in grams and current market value.
- **Collection Flow:** Offline-capable payment recording with automated asset calculation based on daily rates.
- **Withdrawals:** Request partial/full withdrawal with status tracking.

### Admin Portal
- **Dashboard:** Real-time inflow/outflow charts and net cash flow analysis.
- **Customer Management:** Full KYC lifecycle and scheme enrollment engine.
- **Staff Management:** Target setting and route-based allocation.
- **Market Rates:** Automated daily fetch of gold/silver prices via external API.

## 6. Data Model & Schema
- **Profiles:** Core user identity with role-based attributes.
- **Customers:** KYC-compliant records linked to profiles.
- **Schemes:** Definitions for 18 distinct investment products.
- **User_Schemes:** Active enrollments linking customers to specific products.
- **Payments:** Immutable, append-only transaction logs with asset conversion.
- **Withdrawals:** Status-driven requests for asset liquidation.
- **Routes & Assignments:** Geographic mapping for collection agents.

## 7. Technical Architecture
- **Frontend (Web):** Next.js with React and Tailwind CSS.
- **Frontend (Mobile):** Flutter (iOS/Android) for cross-platform efficiency.
- **State Management:** Riverpod for robust and reactive state handling.
- **Backend/Database:** Supabase (PostgreSQL) with Realtime capabilities.
- **Authentication:** Supabase Auth with custom role-based assertions.

## 8. Non-Functional Requirements
- **Performance:** App launch < 2s; database queries < 100ms.
- **Reliability:** 99.5% uptime; offline sync for field staff.
- **Security:** RLS enforced at database level; encrypted storage for PINs.
- **Auditability:** Immutable payment records; full transaction logs.

## 9. UI Requirements
- **Aesthetic:** Premium gold/black theme across all interfaces.
- **Typography:** Playfair Display for headings; Inter for body text.
- **Inputs:** Custom stylized text fields with focus animations.
- **Responsiveness:** Fluid layouts for mobile, tablet, and desktop.

## 10. Integrations
- **Supabase SDK:** Primary backend interface.
- **Market Rate API:** Automated gold/silver price fetching.
- **SMS Gateway:** OTP delivery for customer authentication.
- **Local Storage:** Secure caching for offline field operations.

## 11. Data Access & Security
- **Row Level Security (RLS):** Policies ensure users only access their own data.
- **Role Enforcement:** Server-side validation (RPC) for mobile app access.
- **Encryption:** All data in transit (TLS) and at rest (AES-256).

## 12. Business Rules
- **Payment Immutability:** Payments cannot be edited or deleted once created.
- **Asset Calculation:** Grams are locked at the rate active during the transaction.
- **Enrollment Control:** Customers cannot self-enroll; enrollment must be performed by office staff.
- **Access Hierarchy:** Office staff are prohibited from accessing the mobile app.

## 13. Error Handling & Edge Cases
- **Sync Conflicts:** Last-write-wins or manual resolution for offline payments.
- **Invalid Rates:** System falls back to last known rate if API fetch fails.
- **Session Expiry:** Automatic token refresh and secure logout.

## 14. Testing Requirements
- **Verification queries:** SQL-based validation for all core tables.
- **UI Testing:** Visual verification of gold/black theme consistency.
- **Integration Testing:** End-to-end flow from enrollment (Web) to collection (Mobile).

## 15. Deployment & Environments
- **Hosting:** Vercel (Web), App Store/Play Store (Mobile).
- **CI/CD:** Automated builds and security scanning.

## 16. Monitoring & Logging
- **Real-time Monitoring:** Supabase dashboard for database health.
- **Transaction Logs:** Database-level audit trails for all critical actions.

## 17. Assumptions & Constraints
- **Connectivity:** Reliable internet required for office staff; intermittent allowed for field agents.
- **Hardware:** Modern smartphones (iOS 13+ / Android 8+) required for app users.

## 18. Risks & Mitigation
- **Data Integrity:** Mitigated by RLS and database triggers.
- **Market Volatility:** Mitigated by real-time rate integration.
- **User Adoption:** Mitigated by intuitive, premium UI design.

## 19. Success Criteria
- Zero critical console errors in mobile and web apps.
- Successful end-to-end payment collection flow.
- Verified dashboard accuracy against raw database counts.
- 100% adherence to the gold/black visual identity.

## 20. Appendices
- [SYSTEM_ARCHITECTURE_SPECIFICATION.md](file:///c:/dev/slg-golds/SYSTEM_ARCHITECTURE_SPECIFICATION.md)
- [DATABASE_MIGRATIONS_SPRINT_1_TO_3.sql](file:///c:/dev/slg-golds/DATABASE_MIGRATIONS_SPRINT_1_TO_3.sql)
- [PROJECT_DEFINITION_REPORT.md](file:///c:/dev/slg-golds/PROJECT_DEFINITION_REPORT.md)
