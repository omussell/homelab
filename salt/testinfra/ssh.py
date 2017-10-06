def test_ssh_dir(host):
    ssh_dir = host.file("/etc/ssh")
    assert ssh_dir.is_directory

def test_ssh_config_file(host):
    ssh_config = host.file("/etc/ssh/ssh_config")
    assert ssh_config.is_file

def test_sshd_config_file(host):
    sshd_config = host.file("/etc/ssh/sshd_config")
    assert sshd_config.is_file

def test_ed25519_host_key_file(host):
    ed25519_priv = host.file("/etc/ssh/ssh_host_ed25519_key")
    assert ed25519_priv.is_file

def test_ed25519_host_pub_key_file(host):
    ed25519_pub = host.file("/etc/ssh/ssh_host_ed25519_key.pub")
    assert ed25519_pub.is_file

def test_sshd_running_and_enabled(host):
    sshd = host.service("sshd")
    assert sshd.is_running
    assert sshd.is_enabled
