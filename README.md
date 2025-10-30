# Azure Networking — Troubleshooting (Part 1)

## Before you start
1. Generate ssh key for task
- ssh-keygen -t ed25519 -C "your_email@example.com"
2. Example usage ( Not Recommended in Production Env )
- cat ~/.ssh/id_ed25519.pub
- admin_ssh_public_key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAI... your_email@example.com"


## Description (history)
A teammate deployed a **Linux VM** on **Microsoft Azure** to host a simple web application (e.g., Nginx). Two days later, they reported **connectivity issues**:
- The application is **not reachable from the Internet** via the VM’s public endpoint.
- The VM **cannot reach external resources** required to install/update packages.
- **Management access** to the VM is currently unavailable.

Your task is to **investigate and remediate** the situation so the VM is reachable and operational.

---

## Purpose of the task
- **Identify and diagnose** the factors preventing:
  - inbound access to the web application over **HTTP (port 80)**, and
  - outbound connectivity from the VM to the Internet,
  - as well as **secure administrative access** to the VM.
- **After remediation**, the default app page should be accessible over HTTP, the VM should be able to download packages from the Internet, and there should be a secure, documented way to manage the VM.

---

## Rules and restrictions
- **Allowed:** Remediation using **Terraform (AzureRM)** only.
- **Prohibited:**
  - Opening inbound traffic from **`0.0.0.0/0`** without clear justification (apply least privilege).
  - Changing the **Virtual Network (VNet) address space**.
  - Deleting the entire **Resource Group/stack** to redeploy from scratch.

---

## 3. Best Practices and Tips

- https://learn.microsoft.com/en-us/azure/virtual-network/network-security-groups-overview 

- https://learn.microsoft.com/en-us/azure/cloud-adoption-framework/ready/azure-best-practices/plan-for-virtual-machine-remote-access 

- https://learn.microsoft.com/en-us/azure/security/fundamentals/best-practices-and-patterns 

- https://learn.microsoft.com/en-us/azure/well-architected/service-guides/virtual-machines 


---

## 4. Additional Requirements

Consider and propose Terraform/infrastructure modifications that improve the current solution.  
Focus on the benefits for **cost**, **automation**, **optimization**, and **maintenance** from a DevOps perspective.  
Your goal is to convince your teammate why changing the current approach is worthwhile.

---

## Additional Challenges

1. **Infrastructure as Code** – Implement your upgraded solution in Terraform (code changes included).
2. **Diagram** – Prepare a diagram of the **current** implemented infrastructure to visualize the concept.

> The above are required to complete the task. If you have time and motivation, you may add more functionality and best practices.

---

**Good luck!**