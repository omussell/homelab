### Git

def test_git_is_installed(host):
    git = host.package("git")
    assert git.is_installed
    assert git.version.startswith("2.13.5")

def test_git_remote_user_exists(host):
    git_remote = host.user("git_remote")
    assert git_remote.home == "/nonexistent"
    # man git-shell
    assert git_remote.shell == "/usr/local/bin/git-shell"

def test_git_dir(host):
    git_dir = host.file("/usr/local/git")
    assert git_dir.is_directory
