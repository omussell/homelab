def test_daemontools_is_installed(host):
    daemontools = host.package("daemontools")
    assert daemontools.is_installed
    assert daemontools.version.startswith("0.76")

def test_service_dir(host):
    service = host.file("/var/service")
    assert service.is_directory

def test_svscan_running_and_enabled(host):
    svscan = host.service("svscan")
    assert svscan.is_running
    assert svscan.is_enabled
