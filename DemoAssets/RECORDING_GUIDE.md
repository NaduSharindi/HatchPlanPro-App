# HatchPlan Pro – Screen Recording Guide

Records every feature and both role flows using two simulators side by side:
**iPhone 17 = Supervisor**, **iPhone 17 Pro = Manager**. Allow about 15–20 minutes.

---

## 1. Prepare (once, ~5 minutes)

1. **Firestore rules are published** (Firebase console › Firestore › Rules, paste `firestore.rules`, Publish).
2. In Terminal:
   ```bash
   cd ~/IOS_CW
   ./DemoAssets/prepare_demo.sh --clean
   ```
   This erases both simulators, builds and installs the app, imports the 21 certificates and the egg photos into Photos, and sets the status bar to 9:41 with full battery.
   *Use `--fresh` instead of `--clean` to keep Photos and Face ID but reinstall the app.*
3. In **each** Simulator window: **Features › Face ID › Enrolled**.
4. Arrange the two windows side by side: Supervisor (iPhone 17) left, Manager (iPhone 17 Pro) right.
5. Have two accounts ready, one per role. Create them during the recording (Scene 1) or beforehand in Firebase › Authentication.
6. Optional, for a tidy dataset: delete the `hatchPlans` collection in Firebase › Firestore › Data first. The first device to sign in then seeds a realistic 2-month demo history (batches B1001–B1028).

## 2. Start recording

- **Both phones in one video (recommended):** press **⇧⌘5**, choose **Record Selected Portion**, drag the box around both Simulator windows, open **Options › Microphone** if you want to narrate, then click **Record**. Stop with the ■ button in the menu bar. The video is saved to the Desktop.
- **One phone at a time:** click a Simulator window and press **⌘R** (File › Record Screen). Press ⌘R again to stop.
- **Command line, per device:** `xcrun simctl io booted recordVideo --codec=h264 ~/Desktop/hatchplan.mp4`, then **Ctrl+C** to stop.

Face ID during recording: when a Face ID prompt appears, choose **Features › Face ID › Matching Face** in that window. Choose **Non-matching Face** to demonstrate a failure.

---

## 3. Recording script

| # | Device | What to do | Feature shown |
|---|---|---|---|
| **1** | Supervisor | Launch: splash → welcome pages → **Get Started** → **Hatchery Supervisor** → 3 supervisor intro pages → **Continue to Sign In** | Onboarding |
| 1a | Supervisor | Tap **Forgot Password?**, show the screen, go back | Password reset (Firebase email) |
| 1b | Supervisor | **Sign Up**: name, site *Meegoda*, email, password, accept Terms → **Create Account** | Registration with role and site |
| 1c | Supervisor | **Enable Face ID** → Matching Face | LocalAuthentication |
| **2** | Manager | Same flow with **Hatchery Manager** (manager intro pages differ) → sign up or sign in → enable Face ID | Same flow, both roles |
| 2a | Manager | *(Optional)* sign out, choose **Manager**, enter the **supervisor's** credentials → error "registered as a Hatchery Supervisor" | Role-based access control |
| **3** | Supervisor | Tour **Home**: progress ring, velocity, pipeline, upcoming milestones, sync card | Live dashboard |
| **4** | Supervisor | **New Plan** → **Scan Verified Attached Certificate** → **Choose from Photos** → pick **certificate_B2001** | VisionKit OCR |
| 4a | Supervisor | Point out **7/7 fields** and confidence: batch, flock, breed, age, customer and target are filled in | OCR to auto-fill |
| 4b | Supervisor | Drag the **Safety Buffer** slider; watch eggs and trays recalculate; show the setter-load bar | Smart Calculation Engine |
| 4c | Supervisor | **Send for Approval** → "Request Sent to Manager" | Planning step |
| **5** | Manager | Banner appears; **Approvals** badge goes up; open **Alerts** → **Review Now** | Real-time sync and notifications |
| 5a | Manager | **Home**: hatchability chart (standard vs actual), stats | SwiftUI Charts |
| 5b | Manager | **Map** tab: tap site pins; approval card with setter load | MapKit |
| 5c | Manager | **View Plan Details**: mathematical breakdown, map, certificate image, site history hint | Verification |
| 5d | Manager | **Approve Plan** → Face ID (Matching Face) → **Plan Approved** → signature shown | Digital signature |
| 5e | Manager | **Generate PDF Report** → scroll the 2-page PDF → **Share** → **Save to Files** | PDFKit and share sheet |
| **6** | Supervisor | Repeat Scene 4 with **certificate_B2017** (58-week flock), leave buffer low, submit | Aged-flock warning |
| 6a | Manager | Open it → **Reject** → pick a quick reason → Reject | Rejection with reason |
| 6b | Supervisor | Alert "Needs Changes" → **Batches** → rejected card shows the reason → **Revise & Resubmit** → raise buffer → resubmit | Revise loop |
| 6c | Supervisor | *(Optional)* **certificate_B2009** with site **Halwatura** → over-capacity warning | Capacity check |
| **7** | Supervisor | Alert "Plan Approved" → open batch → **Execute Set** → allow Calendar and Notifications → **Execute Set** → success screen with milestones count | EventKit and reminders |
| 7a | Supervisor | Home button (⇧⌘H) → **Calendar** app → go forward 18 and 21 days to see Transfer and Hatch events | Calendar integration |
| **8** | Supervisor | In the active batch → **Add New Observation** → choose a type → write a note → **Choose Photos** → pick 2–3 **egg photos** → **Done** | Observations with photos |
| 8a | Supervisor | **EDIT** the observation: change type, remove one photo (✕), add one with **Choose Photos** → Done ("edited" label) | Editing |
| 8b | Manager | Open the same batch → the observation and photos appear (read-only); tap a photo to enlarge | Cross-device sync |
| **9** | Supervisor | **Home › View Schedule**: Today/Tomorrow groups, search box | Schedule |
| **10** | Supervisor | Open an incubating batch (e.g. **B1022/B1023** from the demo data, or the one you set) → **Log Hatch Results** → enter chicks → see hatchability and variance → **Close Batch** (confirm early close if asked) | Closing step |
| 10a | Supervisor | **View Performance Report** → PDF now shows actual vs standard | Audit report |
| 10b | Manager | Alerts: "Batch Closed" (and "Below Standard" if under) → **Home** chart updates → **Completed Batches** list | Closing feedback |
| **11** | Either | **Spotlight**: go to the home screen, swipe down, search **B2001** → tap the result → the batch opens in the app | Core Spotlight deep link |
| **12** | Supervisor | **Settings** › tap the profile → **Edit**: photo (camera badge → Photos), job title, employee ID, site, phone → **Save** | Profile synced to Firestore |
| 12a | Supervisor | Toggle **Haptic Feedback**, **Siri & Search**; **Accessibility**: High Contrast on (text bolds), Text Size slider | Preferences and accessibility |
| 12b | Supervisor | **Biometric Authentication** toggles; **Change Password** (show the checklist; you can stop before saving) | Security |
| 12c | Supervisor | **User Manual** (search "buffer"), **Contact Support** (FAQs), **Terms of Service** (accept), **Privacy Policy** | Support and legal |
| 12d | Manager | Open **Settings** to show the same screens for the manager role | Parity across roles |
| **13** | Either | **Sign Out** → relaunch → **Face ID unlock** screen | Biometric session unlock |

### Notes
- **Batch IDs must be unique.** If you re-record, change the Batch ID field before sending (e.g. #B2001 → #B2101), or delete the `hatchPlans` collection.
- **Site selection:** certificates don't set the site. Pick the site matching the certificate's *Destination* line.
- **Approvals require Face ID enrolled** in the Manager simulator (step 1.3); otherwise approval is blocked by design.
- **The camera is unavailable in the Simulator.** "Scan with Camera" and "Take Photo" explain this; use **Choose from Photos**. On a real iPhone, VisionKit's scanner opens instead.
- **Offline demo (optional):** turn the Mac's Wi-Fi off, submit a plan (Home shows "awaiting sync"), turn Wi-Fi on, and it uploads and appears on the Manager.
- **Simulated readings:** temperature, humidity and CO₂ values are placeholders until incubators are connected (future IoT work).
