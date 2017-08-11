def test_jailconf_file(host):
    jailconf = host.file("/etc/jail.conf")
    assert jailconf.contains("testjail1")
