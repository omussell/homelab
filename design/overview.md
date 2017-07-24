% Bootstrapping a Secure Infrastructure
% Oliver Mussell
% 2016-2017

<!---

- Produced in Markdown with Vim, converted to HTML by Pandoc.
- Graphics created with DOT
- Hosted on Github Pages

-->

- [Overview](/homelab/design/overview.html)
- [Design](/homelab/design/design.html)
- [Implementation](/homelab/design/implementation.html)

Summary
===

Create an infrastructure with an emphasis on security, resiliency and ease of maintenance. 

End Goal
===

Produce a working implementation of a secure, resilient and easy to maintain infrastructure. This will be published in the form of version-controlled configuration documents, with the philosophy and background of the chosen configuration documented here. Anyone should be able to download the vendor supplied base operating system, and the configuration documents should convert that base OS into the desired state. The process by which this conversion is achieved could be as simple as a shell script, or as complicated as a configuration management tool backed by continuous deployment pipelines. In addition, the infrastructure should be flexible enough to be deployed in multiple configurations based on the decisions of the Infrastructure Architects and business owners. It should also be portable to other operating systems with only a little massage of the configuration code.

Background
===

The design of the environment will be similar to [Project Athena] at MIT and the [Distributed Computing Environment] by the OSF. Inspiration for this project comes from the [infrastructures.org] website, specifically their papers: [Bootstrapping an Infrastructure] and [Why Order Matters: Turing Equivalence in Automated Systems Administration].





Further, the intent is for the infrastructure to work regardless of participating in the wider internet. The design is aimed at organisations that have strict security and uptime requirements (government/critical physical infrastructure), although there is nothing preventing other organisations from adopting this design and/or changing it to suit them.

Organisations would likely still use the existing internet infrastructure in order to connect between their sites, however, there is the option to not be dependent on the third-party PKI and DNS systems. By removing the dependencies between organisations, there is greater decentralisation which allows more freedom. 

However, a balance should be sought. If an organisation wishes part of its infrastructure, such as a website, to be accessible by the public you would not give them access to your infrastructure but instead host it on another infrastructure for example in the cloud which would be dependent on third party PKI and DNS.





[infrastructures.org]: http://www.infrastructures.org
[Bootstrapping an Infrastructure]: http://www.infrastructures.org/papers/bootstrap/bootstrap.html
[Why Order Matters: Turing Equivalence in Automated Systems Administration]: http://www.infrastructures.org/papers/turing/turing.html

High-Level Design
===
<img src="/homelab/pic/secenv.svg">
