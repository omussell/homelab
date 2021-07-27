class profiles::finn::app (

  #String $testvar = lookup('test::var'),

) {

  package { 'nginx':
    ensure => installed,
  }

}


## ^^^ the old way
#
## The new way:
##https://puppet.com/docs/puppet/7/the_roles_and_profiles_method.html#the_roles_and_profiles_method
#
## Example Hiera data
#profile::jenkins::jenkins_port: 8000
#profile::jenkins::java_dist: jre
#profile::jenkins::java_version: '8'
# 
## Example manifest
#class profile::jenkins (
#  Integer $jenkins_port,
#  String  $java_dist,
#  String  $java_version
#) {
## ...
#
##In general, class parameters are preferable to lookups. They integrate better with tools like Puppet strings, and they're a reliable and well-known place to look for configuration. But using lookup is a fine approach if you aren't comfortable with automatic parameter lookup. Some people prefer the full lookup key to be written in the profile, so they can globally grep for it.
