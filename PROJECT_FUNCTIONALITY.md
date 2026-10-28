# WorkConnect: Comprehensive Functionality Document

This document outlines every inch of functionality implemented within the WorkConnect platform, detailing the architecture, frontend screens, backend services, and advanced operational features.

---

## 1. System Architecture & Tech Stack
- **Frontend (Mobile App)**: Built with **Flutter**. Uses a modern, Tailwind-inspired design system with `Provider` for state management.
- **Backend (AI Matching)**: Built with **Python (FastAPI)**. Processes worker profiles and job descriptions to generate compatibility scores.
- **Database & Real-time Sync**: Powered by **Firebase Firestore**. Handles instant UI updates for chats, job postings, and applications.
- **Authentication**: **Firebase Auth** manages secure user login and registration.

---

## 2. Core Platform Capabilities

### 2.1. Dual-Actor System & Role Switching
- **Unified Accounts**: A single user account can act as both a Worker and an Employer.
- **Instant Role Toggle**: Users can switch between "Worker Mode" and "Employer Mode" directly from the side drawer. This updates their role in Firestore and instantly hot-restarts the app context to load the appropriate dashboard and permissions.

### 2.2. Real-Time Messaging & Unified Inbox
- **Live Chat**: Users can communicate directly through real-time Firestore listeners.
- **System Alerts**: The chat system supports automated "Smart Bubbles" for system-generated events (e.g., contract receipts).

---

## 3. Worker (Tradesperson) Functionality

### 3.1. Profile & Onboarding
- **Skill Profiling**: Workers set up their profiles by defining their primary Trade Category (Plumbing, Carpentry, etc.), Years of Experience, Hourly Rate, and specific text-based skills.
- **Certifications**: Workers can upload and manage certifications (e.g., OSHA 30). The system displays "Active" or "Expiring" badges.

### 3.2. Worker Dashboard
- **Earnings Tracker**: Real-time aggregation of the worker's wallet, summing up all completed and escrowed payments for the week.
- **Compliance Status**: Quick-glance view of certification validity.
- **Recent History**: A list of recently applied jobs with live status updates (Pending, Accepted, Declined).

### 3.3. Browse Jobs Search Engine
- **Full-Text Search**: Workers can type keywords (e.g., "Senior Carpenter") to filter active job postings.
- **Category Chips**: Quick-filter pills allow workers to sort jobs by trade (Electrical, Painting, General Labor).
- **One-Click Apply**: Job cards feature an "Apply Now" button that instantly creates an application document in the database and notifies the employer.

### 3.4. Geo-Fenced "Clock In" System
- **Fraud Prevention**: A dedicated "Clock In" button on the dashboard uses the `geolocator` plugin to capture precise GPS coordinates.
- **Proximity Validation**: The system calculates the distance between the worker and the job site. It requires the worker to be within **100 meters** of the site to successfully log a timestamped entry into the `time_logs` database.

---

## 4. Employer (Hiring Manager) Functionality

### 4.1. Profile & Onboarding
- **Company Identity**: Employers establish their business profile, including Company Name, Industry, and operational location.

### 4.2. Employer Dashboard
- **Live Analytics Bento Grid**: Displays real-time stats including "Active Listings", "New Applicants", and "Market Insights" (e.g., trending average hourly rates calculated dynamically from recent job postings).
- **Interactive OpenStreetMap (Local Talent Map)**: 
  - Replaces static maps with a live, zoomable `flutter_map` utilizing OpenStreetMap tiles.
  - Queries the `time_logs` database to drop live, pulsing markers representing nearby workers who are currently "Clocked In", allowing employers to visually assess local labor supply.

### 4.3. Manage Job Postings
- **Job Creation (Post a Job)**: A form to publish new jobs with Title, Description, Trade Category, Budget ($/hr), and Location.
- **Management Hub**: A dedicated screen listing all published jobs. Employers can see real-time "Applicant Counts" for each specific listing.

### 4.4. AI Smart Matching
- **Algorithmic Vetting**: From the Manage Jobs screen, employers can tap **"AI Match"** on any job. 
- **FastAPI Integration**: The app sends the job requirements and all worker profiles via HTTP POST to the Python FastAPI backend (`/ai/match`).
- **Ranked Results**: The backend scores candidates based on skill overlap and experience, returning a sorted list. The UI renders these as "98% MATCH" cards, allowing the employer to instantly message top candidates.

---

## 5. Digital Contracts & Escrow Payments

### 5.1. Send Offer Workflow (Employer)
- Inside the chat interface, employers have access to a **"Handshake"** icon.
- Tapping this opens a dialog to specify an hourly rate or total contract amount.
- This sends a formal **Digital Contract** into the chat thread, rendered as a distinct orange "Smart Bubble."

### 5.2. E-Sign & Escrow (Worker)
- Workers receive the Digital Contract in their chat feed with an **"E-Sign & Accept"** button.
- Tapping the button executes a multi-step transaction:
  1. The contract status changes to "Accepted."
  2. A verified system message is injected into the chat: *"Contract Accepted. Escrow authorized."*
  3. A payment document is generated in the `payments` collection with the status `held_in_escrow`, securing the funds for the worker while protecting the employer. This instantly reflects on the worker's Dashboard Earnings.
