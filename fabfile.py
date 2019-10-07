from fabric import task

signify_bin = "/bin/signify-openbsd"
signify_pubkey = "/home/oem/homelab/html.pub"
signify_privkey = "/home/oem/homelab/html.sec"
git_root = "/home/oem/homelab"
mkdocs_bin = "/home/oem/.local/bin/mkdocs"
brotli_bin = "/usr/bin/brotli"

@task
def verify(c):
    c.run(f"{signify_bin} -V -p {signify_pubkey} -m {git_root}/docs/index.html -x {git_root}/docs/index.html.sig")
    c.run(f"{signify_bin} -V -p {signify_pubkey} -m {git_root}/docs/index.html.br -x {git_root}/docs/index.html.br.sig")

@task
def sign(c):
    c.run(f"{signify_bin} -S -s {signify_privkey} -m {git_root}/docs/index.html -x {git_root}/docs/index.html.sig")
    c.run(f"{signify_bin} -S -s {signify_privkey} -m {git_root}/docs/index.html.br -x {git_root}/docs/index.html.br.sig")

@task(post=[sign, verify])
def build(c):
    with c.cd(f"{git_root}/mkdocs"):
        c.run(f"{mkdocs_bin} build -d ../docs")
        c.run(f"{brotli_bin} ../docs/index.html")

@task()
def serve(c):
    with c.cd(f"{git_root}/mkdocs"):
        c.run(f"{mkdocs_bin} serve")


