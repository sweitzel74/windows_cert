windows_cert
=======================

Chef cookbook containing a lwrp for installing Pfx Authenticode certificates into a windows certificate store.

Note: the lwrp wraps installation calls with a immediately executing scheduled task.  This is a workaround for an authentication issue when bootstrapping nodes from non-Windows hosts.  

The WINRM gem is used to chef Windows machines and does not currently provide CredSSP or Kerbros authentication (from non-Windows machines).  

This means the execution context for the bootstrapping chef run triggers a "multi-hop" delegation security check that fails when calling the x509 certificate api.  By wrapping the x509 api call in a scheduled task the installation is able to execute in a local, as opposed to remote, context and thereby does not trigger the delegation check.
