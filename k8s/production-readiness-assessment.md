# Production Readiness Assessment

### 1. External Routing

The current Ingress setup works for testing, but it is not ready for real KijaniKiosk customers. The `kk-payments` service handles payment information, but the current Ingress uses HTTP instead of HTTPS. Without TLS, payment information is sent without encryption and could be intercepted while moving between the client and the Ingress. For production, I would create a Kubernetes **TLS Secret** containing the certificate and private key and add it to the Ingress `tls` section. I would also use the NGINX annotation `nginx.ingress.kubernetes.io/ssl-redirect: "true"` to force HTTP traffic to use HTTPS.

TLS is not the only gap. The payment endpoint also needs protection from too many requests. NGINX Ingress supports rate limiting with the `nginx.ingress.kubernetes.io/limit-rps` annotation. This can help prevent one client from sending too many requests and putting unnecessary load on the payment service. Authentication could also be added using the NGINX `nginx.ingress.kubernetes.io/auth-url` feature.

### 2. Health Signalling

The current `kk-payments` probes are working, but I would review them before production. The readiness probe starts after **5 seconds**, checks every **10 seconds**, and allows **3 failures**. The liveness probe starts after **15 seconds**, checks every **20 seconds**, and also allows **3 failures**. These settings are currently working because all three payment Pods are Ready.

However, a real payment service may take longer to start because it may need to connect to a database or other services. I would test the real startup time and increase the initial delay if necessary. A **startupProbe** could also be added to give the application enough time to start before liveness checks begin. If the failure threshold is too low, a temporary database slowdown could cause repeated health-check failures. A readiness failure can remove the Pod from Service traffic even though the application may recover shortly after. If the liveness probe also fails, Kubernetes may restart the container unnecessarily, reducing available capacity and potentially affecting payment transactions.

### 3. Capacity

Three replicas are useful for availability, but manual scaling is not enough for large end-of-month traffic increases. The deployment already has CPU and memory requests, with each payment Pod requesting **100m CPU and 128Mi memory**. For autoscaling, the cluster would also need **metrics-server** and a **Horizontal Pod Autoscaler (HPA)** with suitable minimum and maximum replicas and a CPU target.

If the HPA CPU target is too high, Kubernetes will wait too long before adding Pods. The existing Pods may become overloaded, causing slower responses and failed payment requests. If the target is too low, Kubernetes may create more Pods than necessary. This increases costs and can also create extra database connections and load. The CPU target should therefore be based on real workload measurements rather than simply choosing a very high or very low percentage.
