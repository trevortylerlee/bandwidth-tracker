# Bandwidth Tracker - Code Audit Report

**Date:** 2025-11-14
**Auditor:** Claude
**Version:** Current (v0.0.6)

---

## Executive Summary

This audit identifies **23 issues** across bugs, bad practices, and antipatterns in the Bandwidth Tracker codebase. The codebase is relatively small (~450 lines) and functional, but has several correctness issues, maintainability problems, and performance inefficiencies.

**Severity Breakdown:**
- 🔴 Critical: 3 issues
- 🟡 Medium: 8 issues
- 🟢 Low: 12 issues

---

## 🔴 Critical Issues (Bugs)

### 1. **Session Duration Counting Bug**
**File:** `NetworkMonitor.swift:93`
**Impact:** Session duration keeps incrementing even after app restart, making the metric inaccurate.

**Issue:** The `sessionDuration` is persisted to disk, but continues counting from the saved value on app restart. This means if you close the app and reopen it, the session duration continues from where it left off rather than starting fresh.

**Why it matters:** Users can never get an accurate "session" duration - it becomes a total lifetime duration instead.

---

### 2. **Race Condition in Stats Update**
**File:** `NetworkMonitor.swift:88-104`
**Impact:** Data corruption risk and potential crashes.

**Issue:** The timer runs on a background queue (`.utility`) but accesses and modifies shared state (`needsSaving`, `lastStatsUpdateTime`) from both background and main queues without synchronization.

```swift
// Background queue
timer.setEventHandler { [weak self] in
    // Accesses self.lastStatsUpdateTime (background)
    if now.timeIntervalSince(self.lastStatsUpdateTime) >= 5.0 {
        // Meanwhile, main queue might be reading same property
    }
}
```

**Why it matters:** Race conditions can lead to data corruption, crashes, or unpredictable behavior.

---

### 3. **Network Interface Detection Fragility**
**File:** `NetworkMonitor.swift:130`
**Impact:** App won't track bandwidth for many Mac configurations.

**Issue:** Hard-coded to only check `en0` and `en1` interfaces. Many Macs use different interface names (e.g., `en2`, `en3`, USB tethering uses different names, VPN interfaces, etc.).

```swift
if name == "en0" || name == "en1" {  // Too restrictive!
```

**Why it matters:** App will show 0 bandwidth for users whose primary network interface isn't en0/en1.

---

## 🟡 Medium Priority Issues

### 4. **Unused Code - ContentView.swift**
**File:** `ContentView.swift:10-24`
**Impact:** Code bloat, confusion.

**Issue:** Entire file is unused template code from Xcode. The app uses `MenuBarExtra` and never displays this view.

**Effort:** 30 seconds (delete file)
**Impact:** Reduces confusion, cleaner codebase.

---

### 5. **Unused Code - NetworkDataPoint Struct**
**File:** `NetworkStats.swift:24-36`
**Impact:** Dead code, maintenance burden.

**Issue:** `NetworkDataPoint` struct is defined but never instantiated or used anywhere in the codebase.

**Effort:** 10 seconds (delete struct)
**Impact:** Cleaner models, less confusion.

---

### 6. **Unused State Variable**
**File:** `PopoverView.swift:13`
**Impact:** Memory waste (minimal), confusion.

**Issue:** `@State private var showingResetConfirmation = false` is declared but never used. The reset functionality was moved to SettingsView.

**Effort:** 10 seconds (delete line)
**Impact:** Cleaner code.

---

### 7. **ByteCountFormatter Recreation**
**File:** `ByteCountFormatting.swift:11-23`
**Impact:** Performance waste, unnecessary allocations.

**Issue:** Creates new `ByteCountFormatter` instance on every call. These are expensive to create and should be reused.

```swift
static func string(fromByteCount bytes: Int64) -> String {
    let formatter = ByteCountFormatter()  // Created every time!
    // ...
}
```

**Why it matters:** Called frequently for menu bar updates. Creating formatters is expensive.

---

### 8. **No Data Validation on Load**
**File:** `NetworkMonitor.swift:177-186`
**Impact:** App could load corrupted data, negative values, or impossible states.

**Issue:** When loading stats from disk, no validation is performed. Corrupted JSON could load nonsensical values (negative bytes, impossible speeds, etc.).

**Effort:** Medium
**Impact:** Prevents crashes and weird behavior from corrupted data.

---

### 9. **isMonitoring State Persisted Incorrectly**
**File:** `NetworkStats.swift:11`
**Impact:** Confusing state management.

**Issue:** `isMonitoring` is a runtime state that shouldn't be persisted to disk. It's always `false` when the app restarts anyway, making the persistence pointless.

**Effort:** Low (add `CodingKeys` enum to exclude it)
**Impact:** Cleaner state management.

---

### 10. **Poor Error Handling**
**Files:** `NetworkMonitor.swift:173, 183`
**Impact:** Silent failures, hard to debug.

**Issue:** Errors are only printed to console, which users never see. No user notification, no logging, no recovery.

```swift
} catch {
    print("Failed to save stats: \(error)")  // User never sees this!
}
```

**Effort:** Medium
**Impact:** Better debugging, user awareness of issues.

---

### 11. **Unnecessary Group Wrapper**
**File:** `PopoverView.swift:18`
**Impact:** Code clutter (minimal).

**Issue:** `Group { VStack { ... } }` - the Group serves no purpose here.

**Effort:** 5 seconds
**Impact:** Cleaner SwiftUI code.

---

## 🟢 Low Priority Issues

### 12. **Magic Numbers**
**Files:** Multiple
**Impact:** Maintainability.

**Issue:** Hard-coded values scattered throughout:
- `1000` milliseconds (NetworkMonitor.swift:86)
- `5.0` seconds (NetworkMonitor.swift:99)
- `60` seconds (NetworkMonitor.swift:20)
- `250` width (PopoverView.swift:68)
- `420` width (SettingsView.swift:37)

**Effort:** Low
**Impact:** Easier to tune and understand.

---

### 13. **Unused Imports**
**Files:** Multiple
**Impact:** Compilation time (minimal).

**Examples:**
- `Network` imported but unused in `Bandwidth_TrackerApp.swift:9`
- `SystemConfiguration` imported but unused in `Bandwidth_TrackerApp.swift:11`
- `Charts` imported but unused in `Bandwidth_TrackerApp.swift:13`

**Effort:** 1 minute
**Impact:** Faster compilation, cleaner code.

---

### 14. **No Documentation**
**Files:** All
**Impact:** Onboarding, maintainability.

**Issue:** No comments, no function documentation, no explanations of complex logic (especially network interface reading).

**Effort:** Medium
**Impact:** Easier for others (or future you) to understand code.

---

### 15. **No Tests**
**Impact:** Confidence in changes, catching regressions.

**Issue:** Zero test coverage. No unit tests, no integration tests.

**Effort:** High
**Impact:** High (but high effort, so not in quick wins)

---

### 16. **Timer Not Properly Managed in resetStats**
**File:** `NetworkMonitor.swift:188-197`
**Impact:** Potential race condition.

**Issue:** `stopMonitoring()` then `startMonitoring()` could create brief moment where timer is in undefined state.

**Effort:** Low
**Impact:** More robust reset logic.

---

### 17. **No App Version Tracking**
**Impact:** Future data migrations will be difficult.

**Issue:** No version field in persisted data. When you need to migrate data format in future versions, you'll have no way to know what version the saved data is.

**Effort:** Low
**Impact:** Future-proofing.

---

### 18. **File I/O in deinit**
**File:** `NetworkMonitor.swift:44-46`
**Impact:** Potential data loss.

**Issue:** `deinit` calls `saveStats()` which does file I/O. If app is force-quit or crashes during deinit, data might not save.

**Effort:** Medium
**Impact:** Better data persistence reliability.

---

### 19. **Tight Coupling to File System**
**File:** `NetworkMonitor.swift`
**Impact:** Testability, flexibility.

**Issue:** NetworkMonitor is directly coupled to file system persistence. Can't easily test without file I/O, can't swap storage mechanisms.

**Effort:** Medium
**Impact:** Better architecture, more testable.

---

### 20. **Mixed Responsibilities**
**File:** `NetworkMonitor.swift`
**Impact:** Single Responsibility Principle violation.

**Issue:** NetworkMonitor does too much: network monitoring, data persistence, notification handling, timer management.

**Effort:** High
**Impact:** Better architecture.

---

### 21. **Default Display Mode May Be Confusing**
**File:** `AppSettings.swift:40`
**Impact:** User experience.

**Issue:** Default is `.totalInMenuBar` which shows cumulative totals. For a menu bar app, most users expect to see current speed (which is what most similar apps show).

**Effort:** 5 seconds
**Impact:** Better first-run experience.

---

### 22. **No Async/Await Usage**
**Files:** `NetworkMonitor.swift`
**Impact:** Modern Swift patterns.

**Issue:** Uses older GCD patterns instead of modern async/await (though GCD is fine for this use case).

**Effort:** Medium
**Impact:** More modern codebase.

---

### 23. **Hard-coded Stats File Location**
**File:** `NetworkMonitor.swift:19`
**Impact:** Limited flexibility.

**Issue:** Stats file location is hard-coded to documents directory. No configuration option.

**Effort:** Low
**Impact:** More flexible.

---

## 🎯 High Impact, Low Effort Actions (Prioritized)

These are the changes you should tackle first - maximum benefit for minimal time investment:

### Priority 1: Quick Wins (< 5 minutes total)

1. **Delete `ContentView.swift`** ⏱️ 30 seconds
   - Removes dead code
   - File: `Bandwidth Tracker/ContentView.swift`

2. **Delete `NetworkDataPoint` struct** ⏱️ 10 seconds
   - Removes dead code
   - File: `NetworkStats.swift:24-36`

3. **Delete unused `showingResetConfirmation` state** ⏱️ 10 seconds
   - File: `PopoverView.swift:13`

4. **Remove unnecessary Group wrapper** ⏱️ 5 seconds
   - File: `PopoverView.swift:18`
   - Change `Group { VStack { ... } }` to just `VStack { ... }`

5. **Remove unused imports** ⏱️ 1 minute
   - Remove `Network`, `SystemConfiguration`, `Charts` from `Bandwidth_TrackerApp.swift`

**Total time: ~2 minutes | Impact: Cleaner codebase, 4% code reduction**

---

### Priority 2: Critical Bug Fixes (< 30 minutes total)

6. **Fix session duration bug** ⏱️ 5 minutes
   - Don't persist `sessionDuration` or reset it on app launch
   - File: `NetworkStats.swift` + `NetworkMonitor.swift:31-35`
   - Add `CodingKeys` enum to exclude from persistence

7. **Optimize ByteCountFormatter** ⏱️ 5 minutes
   - Make formatters static/cached
   - File: `ByteCountFormatting.swift`
   ```swift
   private static let formatter: ByteCountFormatter = {
       let f = ByteCountFormatter()
       f.allowedUnits = [.useBytes, .useKB, .useMB, .useGB]
       f.countStyle = .binary
       return f
   }()
   ```

8. **Fix network interface detection** ⏱️ 15 minutes
   - Change to detect any non-loopback interface
   - File: `NetworkMonitor.swift:130`
   - Replace `if name == "en0" || name == "en1"` with proper check
   ```swift
   // Skip loopback and only count AF_LINK interfaces
   if !name.starts(with: "lo") && interface.ifa_addr.pointee.sa_family == UInt8(AF_LINK) {
   ```

**Total time: ~25 minutes | Impact: Fixes 3 critical bugs**

---

### Priority 3: Code Quality Improvements (< 20 minutes total)

9. **Extract magic numbers to constants** ⏱️ 5 minutes
   - Create private constants at top of classes
   ```swift
   private enum Constants {
       static let updateInterval: TimeInterval = 1.0
       static let statsUpdateInterval: TimeInterval = 5.0
       static let saveInterval: TimeInterval = 60.0
   }
   ```

10. **Add data validation on load** ⏱️ 10 minutes
    - Validate loaded stats have sensible values
    - File: `NetworkMonitor.swift:177-186`
    ```swift
    func isValid() -> Bool {
        return totalUploaded >= 0 &&
               totalDownloaded >= 0 &&
               downloadSpeed >= 0 &&
               uploadSpeed >= 0
    }
    ```

11. **Change default display mode** ⏱️ 5 seconds
    - Change from `.totalInMenuBar` to `.speedInMenuBar`
    - File: `AppSettings.swift:40`

**Total time: ~15 minutes | Impact: Better UX, more maintainable code**

---

### Priority 4: Thread Safety (< 30 minutes)

12. **Fix race condition** ⏱️ 20 minutes
    - Add proper synchronization for shared state
    - Options:
      - Move all timer work to main queue (simple)
      - Add actor isolation (modern Swift)
      - Use locks/queues properly (traditional)
    - Recommended: Move timer to main queue since it's already dispatching to main for UI updates

**Total time: ~20 minutes | Impact: Eliminates data corruption risk**

---

## Summary: Recommended Action Plan

### Phase 1: Quick Cleanup (2 minutes)
- Delete dead code
- Remove unused imports
✅ Zero risk, immediate payoff

### Phase 2: Critical Fixes (45 minutes)
- Fix session duration persistence bug
- Fix network interface detection
- Optimize formatter
- Fix race condition
✅ Fixes 3 critical bugs, improves performance

### Phase 3: Polish (15 minutes)
- Extract magic numbers
- Add validation
- Change default mode
✅ Better maintainability and UX

**Total investment: ~60 minutes for dramatic improvement**

---

## Not Recommended (High Effort, Lower Priority)

These are valid improvements but require more effort:

- Adding comprehensive test coverage (High effort, High value - but long-term)
- Refactoring to separate concerns (High effort, Medium value - works fine now)
- Moving to async/await (Medium effort, Low value - current code works)
- Adding extensive documentation (Medium effort, Medium value)

---

## Testing Recommendations

After making changes, test these scenarios:

1. **Fresh install** - App works with no saved data
2. **App restart** - Data persists and loads correctly
3. **System sleep/wake** - Continues tracking after sleep
4. **Different networks** - Works on WiFi, Ethernet, USB tethering
5. **Long running** - No memory leaks after hours of running
6. **Network switching** - Handles switching between networks
7. **Force quit** - Data saves even on force quit

---

## Maintenance Recommendations

### Regular Tasks
- Monitor crash reports from users
- Check for deprecated API usage after macOS updates
- Update dependencies

### Future Enhancements (with proper foundation)
- Network usage history/graphs (NetworkDataPoint was likely for this)
- Per-app bandwidth tracking
- Export data functionality
- Custom refresh intervals
- Support for custom network interfaces

---

## Conclusion

The codebase is functional but has several correctness and quality issues. The good news: most issues are quick to fix! Following the prioritized action plan above will result in a significantly more robust, maintainable, and correct application in about 1 hour of focused work.

**Key Takeaway:** Focus on Phase 1 and 2 first - they fix real bugs and take minimal time.
