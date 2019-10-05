from fabric import task

signify_bin = "/bin/signify-openbsd"
signify_pubkey = "/home/oem/homelab/html.pub"
signify_privkey = "/home/oem/homelab/html.sec"
git_root = "/home/oem/homelab"
mkdocs_bin = "/home/oem/.local/bin/mkdocs"

@task
def verify(c):
    c.run(f"{signify_bin} -V -p {signify_pubkey} -m {git_root}/docs/index.html -x {git_root}/docs/index.html.sig")

@task
def sign(c):
    c.run(f"{signify_bin} -S -s {signify_privkey} -m {git_root}/docs/index.html -x {git_root}/docs/index.html.sig")

@task(post=[sign, verify])
def build(c):
    with c.cd(f"{git_root}/mkdocs"):
        c.run(f"{mkdocs_bin} build -d ../docs")

@task()
def serve(c):
    with c.cd(f"{git_root}/mkdocs"):
        c.run(f"{mkdocs_bin} serve")
