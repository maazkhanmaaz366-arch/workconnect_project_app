# WorkConnect Design Documentation & System Architecture

## 1. Project Vision
WorkConnect is an AI-powered marketplace designed to bridge the gap between skilled daily wage laborers (Workers) and homeowners or contractors (Employers). The platform prioritizes **trust**, **speed**, and **fairness** through AI-driven matching and a transparent verification system.

---

## 2. Design Concept & Rationale

### Visual Identity
*   **Color Palette:** 
    *   **Navy Blue (#1a365d):** Used as the primary color to evoke professional stability, trust, and industrial reliability.
    *   **Safety Orange (#e67e22):** Used for primary actions (CTAs) and "Urgent" alerts, mirroring the high-visibility gear used in construction and trades.
*   **Typography (Inter):** A clean, highly legible sans-serif font chosen for its modern feel and readability on mobile devices in varied lighting conditions (e.g., on-site).
*   **Card-Based Layout:** Information is encapsulated in distinct cards to provide clear visual hierarchy and ease of scanning on small screens.

### Design Principles
1.  **AI Transparency:** AI insights (Match scores, wage suggestions) are styled with a distinct "Sparkle" icon and subtle background tints to differentiate machine-generated advice from user data.
2.  **Trust Signals:** Verification badges and rating stars are prominently placed to lower the barrier of entry for hiring strangers.
3.  **Efficiency First:** Large touch targets and high-contrast primary buttons ensure the app is usable by workers who may be on-site or in motion.

---

## 3. The Dual-Actor Ecosystem

### Flow A: The Worker's Journey
*Goal: Find consistent work, track earnings, and build a digital reputation.*

1.  **Onboarding:** AI categorizes plain-text skills into structured tags (e.g., "I fix pipes" → Plumber).
2.  **Discovery:** The "Browse Jobs" feed ranks listings by **AI Match %**, helping workers find jobs they are most qualified for.
3.  **Management:** A dedicated "Home" dashboard tracks active tasks and weekly earnings, providing a sense of progress.
4.  **Reputation:** The profile serves as a digital CV, showcasing a "Verified" badge and a visual work portfolio.

### Flow B: The Employer's Journey
*Goal: Find skilled, reliable labor with zero friction.*

1.  **Posting:** AI detects job categories in real-time as the employer types, ensuring the job is seen by the right workers.
2.  **Hiring:** The "Smart Matching" interface sorts applicants by skill-fit, rating, and distance, reducing the time spent vetting.
3.  **Execution:** Real-time chat allows for coordination without sharing personal phone numbers, maintaining platform privacy.
4.  **Closure:** A post-job rating flow feeds back into the worker's reputation, closing the trust loop.

---

## 4. Key Screens & Navigation Map

| Screen | Perspective | Primary Function |
| :--- | :--- | :--- |
| **Home Dashboard** | Worker / Employer | High-level status overview (Earnings vs. Listings). |
| **Browse / Manage Jobs** | Worker / Employer | Job discovery vs. Applicant oversight. |
| **Messages Inbox** | Shared | Central hub for coordination and AI system alerts. |
| **AI Matching** | Employer | Ranked list of candidates with match rationale. |
| **Profile Page** | Shared | Showcase of skills and history (Worker) or Hiring Credibility (Employer). |
| **Side Drawer** | Shared | Account settings and the critical "Switch Role" toggle. |

---

## 5. Technical Design Notes
*   **Mobile-First:** The entire design is optimized for portrait mobile use, reflecting the "on-the-go" nature of the workforce.
*   **Component Architecture:** Shared headers, bottom navigation, and card structures ensure a cohesive experience as users switch between worker and employer roles.
