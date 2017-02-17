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

The design of the environment will be similar to [Project Athena] at MIT and the [Distributed Computing Environment] by the OSF. Inspiration for this project comes from the [infrastructures.org] website, specifically their papers: [Bootstrapping an Infrastructure] and [Why Order Matters: Turing Equivalence in Automated Systems Administration]. Additionally, a paper by Paul Schenkeveld, [Building servers with NanoBSD, ZFS and Jails] served as inspiration for the use of NanoBSD as the operating system due to its unique properties.

This project aims to extend the work of infrastructures.org and Paul Schenkeveld, by emphasising security and producing a working implementation that can be used by anyone.

[infrastructures.org]: http://www.infrastructures.org
[Bootstrapping an Infrastructure]: http://www.infrastructures.org/papers/bootstrap/bootstrap.html
[Why Order Matters: Turing Equivalence in Automated Systems Administration]: http://www.infrastructures.org/papers/turing/turing.html
[Building servers with NanoBSD, ZFS and Jails]: https://2010.asiabsdcon.org/papers/abc2010-P4A-paper.pdf
[Project Athena]: https://en.wikipedia.org/wiki/Project_Athena
[Distributed Computing Environment]: https://en.wikipedia.org/wiki/Distributed_Computing_Environment

High-Level Design
===
<!---

- Control Machine - Stores operating system images and configuration files in version control. Used to create the Gold server. 
- Gold server - In the form of a created system image
- Infrastructure servers - Provides directory, domain names, authentication/authorisation services
- Data storage - Provide clients with access to their data/files via network file systems.
- Clients - End use

--->

<img src="/homelab/pic/secenv.svg">
<img src="/homelab/pic/disklayout.svg">

