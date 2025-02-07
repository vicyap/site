%{
  title: "AWS RDS Reverse Proxy",
  date: "2025-02-07",
  tags: ~w(aws networking)
}
---

## TLDR

## The Problem

As a DevOps consultant and contractor, I have had to help at least two clients access an AWS RDS database running in private subnets from outside of its VPC.

One reason is that the database was originally public (oops!) and legacy applications and services still assume they can reach the database as if it were public. Once the database has been moved to private subnets, these legacy applications and services need a temporary window of time to also be moved into the same VPC or adjust how they are going to connect to the database.

Another reason is that the RDS database might be created by a vendor in your account, and you have a new requirement to allow your applications to connect to that database, but your applications may be running in a different cloud provider (ie. multi-cloud).

So, what solutions are there to access an RDS database in private subnets from outside of its VPC?

## Solutions

1. **VPN / Tailscale / Direct Connect / Transit Gateway** (some form of secure network extension)
2. **Network Load Balancer (NLB) Reverse Proxy + IP Allowlists With End-to-End SSL/TLS**

Certainly, you could get creative and come up with more ideas, but I believe these two are the best balance between developer ease, infrastructure complexity, costs and security.

### Comparison Table

| Aspect                             | VPN / Tailscale / DX / TGW                                                                                                                 | NLB Reverse Proxy + SSL + IP Allowlists                                                                              |
|------------------------------------|---------------------------------------------------------------------------------------------------------------------------------------------|---------------------------------------------------------------------------------------------------------------------|
| **Developer Ease**                 | If devs already use Tailscale/VPN, they just connect to the private RDS endpoint. Otherwise, they must install and configure a VPN client.   | Devs use a public DNS with Postgres SSL; no extra VPN client needed. Their IP must be in the allowlists.                  |
| **Infrastructure**                 | More initial work: configure Tailscale subnet router, Site-to-Site VPN, or Transit Gateway. Can be more complex to set up.                  | Minimal setup: create NLB in a public subnet, register RDS as target, configure IP allowlists.      |
| **Maintenance**                    | After initial setup, day-to-day is typically minimal. Tailscale often updates automatically; AWS manages the VPN gateway if using Site-to-Site. | AWS manages the load balancer. You only maintain IP allowlists. No OS patching or multi-AZ concerns.                             |
| **Costs**                          | Tailscale can be free or low cost if usage is small; AWS VPN is about $36 per month plus data. Larger solutions (TGW, DX) can be more expensive.  | Around $16 per month for NLB in us-east-1 plus data egress fees. No extra EC2 needed.                                  |
| **Security**                       | No public endpoint at all; fully private tunnel or overlay with encryption. Most secure if you want zero public exposure.    | RDS is private; only the NLB endpoint is exposed, restricted by IP allowlists. Traffic is SSL-encrypted end-to-end. |

### Bottom Line

1. **VPN / Tailscale / Direct Connect / Transit Gateway**  
   - **Pros**: Zero external exposure. All traffic is over a private or encrypted tunnel. Very “best practice” if your organization already uses such a solution.  
   - **Cons**: Higher up‐front complexity. Devs and external services must be on that private network or have a VPN/Tailscale client.
2. **NLB Reverse Proxy + SSL + IP Allowlists**  
   - **Pros**: Quick to set up, completely managed in AWS, and no plain text traffic with SSL.
   - **Cons**: You do have a public LB, although restricted by IP allowlists and encrypted with SSL.

## Implementation

### VPN / Tailscale / Direct Connect / Transit Gateway

I am going to skip this solution because of the following reasons:

* It varies a lot based on your existing secure network setup.
* If you are not already using Tailscale or a VPN, then there is added effort to get developers to install clients and configure them.
* It might not be possible to use this solution if your external environment (ie. other cloud) cannot connect via VPN or Tailscale.
* It could be blocked on management approval or security concerns.

Whereas, the NLB Reverse Proxy + SSL + IP Allowlists solution can be completely implemented within AWS and does not require changes to your external environment.

### NLB Reverse Proxy + SSL + IP Allowlists

#### Diagram

![AWS RDS Reverse Proxy with NLB Diagram](/images/diagrams/0004-aws-rds-reverse-proxy-nlb.drawio.svg)

#### Infrastructure as Code

If you use Infrastructure as Code (IAC) tools like AWS CloudFormation or Terraform, I have written a template file and/or Terraform module you can use.

**AWS CloudFormation Template**:

```yaml
```

**Terraform Module**:

```hcl
```

#### Step-by-Step Guide

1. **Create a Network Load Balancer (NLB)**:
   - Create an NLB in a public subnet.
   - Configure it to listen on port 5432 (or your desired port)
   - Register your RDS instance as a target.
