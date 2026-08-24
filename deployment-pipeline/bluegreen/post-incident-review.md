# Post-Incident Review: KijaniKiosk Deployment Incident

## Section 1: Incident Summary

During an investor demonstration, the KijaniKiosk staging service experienced a 48-second interruption. A deployment change was applied to the wrong environment because the deployment target was incorrectly selected. The service was restored after the incorrect configuration was identified and reverted.


---

## Section 2: Timeline

The timeline below is a reconstruction from the incident description. The timestamps are marked as estimated because the original incident logs were not available.

09:12 (estimated): Nia begins the investor walkthrough using the KijaniKiosk staging environment.

09:15 (estimated): Amina starts a deployment process with an incorrect environment selection, causing the change to target production instead of staging.

09:15 (estimated): The deployment process applies the configuration changes to the production environment.

09:16 (estimated): The affected service restarts using the new configuration.

09:16 (estimated): The staging demonstration is affected and the expected service response is unavailable.

09:17 (estimated): Tendo is notified that there is a problem during the demonstration.

09:18 (estimated): Tendo investigates and identifies that the deployment used the wrong environment setting.

09:19 (estimated): Tendo restores the previous configuration to return the service to its known working state.

09:20 (estimated): The service is confirmed operational again. The total user-visible impact was 48 seconds.

---

## Section 3: Root Cause

The immediate cause was a deployment being applied to the wrong environment. The deeper issue was that the deployment process allowed the environment target to be manually selected without enough validation or protection.

### Five Whys Analysis

**Why was the wrong environment changed?**
Because the deployment was directed to production instead of the intended staging environment.

**Why could the deployment target be incorrect?**
Because the environment value was manually provided during the deployment process.

**Why was the environment value manually provided?**
Because the deployment workflow did not automatically determine and verify the correct environment.

**Why was there no verification step?**
Because environment protection and validation controls were not included in the deployment process.

**Why were these controls missing?**
Because the deployment workflow had not been updated with safeguards to prevent environment mismatches.

**Root Cause:**
The deployment system allowed manual environment selection without automated validation, creating a risk that changes could be applied to the wrong environment.

---

## Section 4: Contributing Factors

* The deployment process relied on a manually entered environment value.

* There was no automated check confirming that the selected environment matched the intended deployment target.

* Environment access and deployment controls did not provide enough protection against accidental cross-environment changes.

---

## Section 5: What Went Well

* The issue was detected quickly during the demonstration.

* The team was able to identify the incorrect environment setting and restore the previous working configuration.

* The incident created clear areas for improving deployment safety controls.

---

## Section 6: Action Items

### Action 1: Add automatic environment validation

Owner: DevOps Engineer
Target timeframe: Within one week

Implement checks that confirm the deployment target before allowing changes to proceed.

### Action 2: Add protected environment approval controls

Owner: Engineering Lead
Target timeframe: Within two weeks

Require additional approval before changes can be applied to protected environments.

### Action 3: Improve separation between environments

Owner: Platform Engineer
Target timeframe: Within two weeks

Strengthen environment access controls so an incorrect deployment target cannot easily affect another environment.
