# KijaniKiosk Payments Service Level Objectives (kk-payments)

## Service Overview

The kk-payments service processes payment transactions. The reliability objectives measure whether payment requests are successful, fast enough for customers, and not failing due to service-side errors.

# Service Level Indicators (SLIs)

## 1. Availability SLI

**What it measures:**

The proportion of payment requests that receive a successful HTTP response from the kk-payments service.

**Data source:**

Application access logs or reverse proxy access logs.

**Measurement method:**

Successful payment requests are measured by counting HTTP 2xx responses and dividing by the total number of payment requests during the measurement window.

**Calculation:**

Successful payment requests ÷ Total payment requests × 100



## 2. Latency SLI

**What it measures:**

The proportion of payment requests served within the target response time, measured using the 95th percentile (p95) response latency.

**Data source:**

Application access logs or reverse proxy access logs containing request response times.

**Measurement method:**

Request response times are collected from access logs and analysed using percentile measurement. The p95 value shows the response time where 95% of requests are completed within the target threshold.


## 3. Payment Error Rate SLI

**What it measures:**

The proportion of payment processing requests that return server-side errors from the kk-payments service.

**Data source:**

Application logs and reverse proxy access logs.

**Measurement method:**

Payment failures are measured by counting HTTP 5xx responses on payment processing requests and dividing by the total number of payment requests.

**Calculation:**

Payment requests returning 5xx errors ÷ Total payment requests × 100



# Service Level Objectives (SLOs)

| SLI | Target | Measurement Window | Error Budget |
|-----|--------|-------------------|--------------|
| Availability | 99.9% of payment requests receive successful responses | Rolling 30 days | 43.2 minutes of permitted downtime |
| Latency | 95% of payment requests served within 500ms | Rolling 30 days | 5% of requests may exceed 500ms |
| Payment error rate | Fewer than 0.1% of payment requests return 5xx errors | Rolling 30 days | Maximum 1 failed request per 1,000 payment requests |



# Rollback Threshold Justification

The rollback thresholds used during deployment are more conservative than the long-term SLO targets. The SLOs describe acceptable service behaviour over a 30-day period, while rollback thresholds detect deployment problems quickly before they consume the error budget.

| SLI | Rollback Threshold | Relationship to SLO |
|-----|-------------------|---------------------|
| Availability | 3 consecutive failed health checks | More conservative because a deployment failure is detected immediately instead of waiting for availability to fall below the 99.9% target over 30 days. |
| Latency | Health endpoint response time above 2 seconds | More conservative because the rollback threshold detects severe latency immediately, while the SLO allows p95 latency up to 500ms across normal traffic. |
| Payment error rate | More than 2 errors during the monitoring window | More conservative because early failures after deployment may indicate a faulty release before the long-term error rate target is breached. |

The rollback monitor uses short-term thresholds because deployment failures need immediate action. The SLOs measure overall reliability over time, while rollback protects customers during a change.



# What We Do Not Commit To

The kk-payments SLOs measure failures that are controlled by the payment service. The following areas are excluded:

**Third-party payment provider availability:**

Failures caused by external payment gateways are excluded because kk-payments cannot control the availability of external providers.

**Customer input validation failures:**

Payments rejected because customers provide invalid payment details are excluded because the service is correctly processing invalid requests.

**Planned maintenance:**

Scheduled maintenance periods communicated in advance are excluded because they are controlled operational activities rather than unexpected service failures.

The SLO measurements include failures caused by kk-payments application errors, incorrect deployments, service crashes, and internal configuration problems because these are failures the engineering team is responsible for preventing.
