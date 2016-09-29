# OS Image Changes

OS images are stored in S3 bucket [bosh-os-images](http://s3.amazonaws.com/bosh-os-images/).


## Ubuntu 14.04

Ubuntu 14.04 images have filename `bosh-ubuntu-trusty-os-image.tgz`

* `MPL_Rw15ozJPumy6wqB1sFcl_h3RZyQp`
  - USN-3087-2: OpenSSL regression
  - build from 257.x-3263.x (f95f6355f4072501b2adcad72603ed558380b5d0)

* `OUw7AQndSV3uHlQkE4VIy5KmI3TkXmnY`
  - USN-3087-1: OpenSSL vulnerabilities
  - build from 257.x-3263.x (4a25cba4e8a376337a877cba5ab773fe4512da8a)

* `tk6W0QWML8TQi4a6VrEEU8YxUcnzbTcg`
  - USN-3084-*: kernel vulnerabilities
  - built from 257.x-3263.x (793365982c27b4f6a49aa90b95f514f1ffe56677)

* `u9jAubTwJXggujmLtC_6g0PiFIY_rGqh`
  - bump kernel to xenial
  - built from 257.x-3263.x (f7d23f435d18b4d7ad1aa1f76ae315630d70d7c9)

* `sKQZ9Gaut79JCdB5_OTZP55rvnKCd9Hl`
  - Backport azure ephemeral disk on root (4548e8e)
  - Backport google file perms fix (d5b1ac9)
  - Backport disable ssh host key gen (444bb0e)
  - Backport hostname length fix (74893f2)
  - Backport udf kernel change (38d42b7)
  - Backport tcp keepalive (079d956)
  - Add logic to check if rsyslogd pid file exists before attempting to kill the process by pid (506c939)
  - kill HUP rsyslog upon logrotation (4395509)
  - build from 257.x (2dcd4799eaf8ee8daf44a5d3dfeed8b58cdf9fe9)

* `CLLx.YB7_OnssvekBlIRFOeWSQw4La8j`
  - rsyslog is started with upstart
  - built from 257.x (bc7bca3351bdbb8b34caf070a4e38222cdd45f63)

* `H2G5oPd_fOiXTlHxX7voCR4E3ncxQAO3`
  - backport IPv6, /var/log, and /tmp mount fixes
  - built from 257.x (8f958578de96af4234a0b4262c77d0778cdecd3a)

* `YYoAwl99cHkRiGPU9zLy74qQuWuPbl1W`
  - USN-3065-1: Libgcrypt vulnerability
  - built from 257.x (623309e8f61b317ad0b01b32a14c9516910b0851)

* `OSizSd9nykb4nJhqibd1_fygZxqVoqam`
  - revert xenial -> vivid
  - built from 257.x (a6ba6c7cb071aee92374a61f0aeef4be46482390)

* `bdLvwz7.6amrKKAPZYj_Tdd2dK8tXjea`
  - update vivid -> xenial
  - periodic bump
  - built from 257.x (e75a2e1e0b2904281fc334969fa68da22748cd67)

* `x2_FVfGn0gf54_BX79gD7B4zJ2ENMXYy`
  - USN-3020-1: Linux kernel (Vivid HWE) vulnerabilities
  - built from develop (383e11d66bb5326eaa342ca695e1b416b50b5c56)

* `OIJ7Qeu3QZMG3J0rSoI6lx8hdcZfaV5R`
  - update for CIS tests
  - built from develop (99aebc025dc4093981395d75be52369ced2d7131)

* `Nh0.et3GyuktazQ9_jOwJGqByyicDrgV`
  - update for CIS tests
  - built from develop (a8d26078eb4a2fb277068381c76da638f40b5b36)

* `oPXNdD8b5WwJXZZQBEYmdIVT1.Om7z2T`
  - update nginx to 1.11.1
  - built from develop (1af67b94cad42ff2133e383afd6d174721253dbc)

* `ApGJBfSesa7VFhEu3RLRTIqiL1R7E_3J`
  - update for CIS tests
  - built from develop (3dfd04cd65c73a01e2f2f1b7310a33687ab27111)

* `odCwzNL6fL14dOpN4SLDwru.6_LCooLl`
  - USN-2977-1: Linux kernel (Vivid HWE) vulnerability
  - built from develop (ce8e1284890e0079923f26533c0e0f7f6c5b6a0e)

* `YsMYRqAqNEpQPA1bNtE26bg3zH6eR9qP`
  - periodic bump with rsyslog reload changes
  - built from develop (15a4ef77db335b186d183323f5a1f6819c35bdce)

* `IstSjjYJuckEZbTJZ9wcV12hYiX2Nzca`
  - bumped for USN-2959-1: OpenSSL vulnerabilities
  - built from develop (95f5d9cc816f934db64a80188cf0c9e80ab15dda)

* `GvyJwqBPjPEYBVCYrUHp0R7qJUHcTJGD`
  - includes gov1 STIGs
  - built from develop (4bc83146a59ddca85d4a56868e520f938dc84843)

* `zABsJmjq2gQgXzmDmAA7ONmkzNeM4ujN`
  - periodic bump to include STIGs
  - built from develop (a6d4a075ad2c58a629fbc9225d75d67cb4c1cd8a)

* `tH3RcRee0EKRX7RMmELCMEfXXq0ulnik`
  - periodic bump to include STIGs
  - built from develop (51750c70da03484321c7c72346742de257bf2fa5)

* `0M3jbAU705ItzZKPdmh6kxRJR38fmvcf`
  - bumped for libpcre3_1:8.31-2ubuntu2.1 vulnerability
  - built from master (d2f73ee7636f2325bf6998670228682d194627c9)

* `sLe0Rz_sFs0Uy2DcZ9Xf3KQG0QsuUXos`
  - periodic bump to include STIGs
  - built from develop (da0fda1f8bb8ee4c63e64a549bfe3727a6ac5b69)

* `C3YA77iYjAp4OazIG8ZTi7AtPVC6pOY2`
  - periodic bump to include STIGs
  - built from develop (c6c341baee219b90935430ef120f52fce668f496)

* `djw1b9mXYwbOSDPGJoFLktHLv79kbcz_`
  - periodic bump to include STIGs
  - built from develop (597cbcd96e631678f7d66c31e39a2ac7ddc6c89d)

* `w02UF1DU9KaAxqxP_LcLiBp0P1.cZh3T`
  - periodic bump to include STIGs
  - built from develop (7437419b800cdaf2a163fc5606ec360032f37a28)

* `tLeFEoNpFBrwBQbY5jjhOVpAVMSY7UHC`
  - USN-2932-1: Linux kernel (Vivid HWE) vulnerabilities
  - built from master (8f4f73a435acfe6728c2588d55d876476b19b725)

* `.ZN3wb_t45goM3wS4rHRGIamJRCmRsuq`
  - periodic bump

* `2GWd6igY_k.UstpTga8U5nVt6Wh7wQUk`
  - bump kernel to 3.19.0-51

* `MowCFiZ6MRwCv0BrPlXLOm7rBUqo5X7e`
  - USN-2910-1: Linux kernel (Vivid HWE) vulnerabilities
  - built from 3197.1 (ea8b8edc196f6650d4a772bc90e3ee8613056c91)

* `ar7dTtxvhG5d_ytxQ_Js9NDb6ePJV5Jt`
  - update for USN-2900-1: GNU C Library vulnerability
  - includes custom kernel update to fix aufs problem
  - built from 3146.8-os-image (b3122f03ec74c227dad8d6f6c5e730bc4eeafca4)

* `3KSsEYj8q18vJPJfngAjPD2TJqUxwILf`
  - custom kernel update to fix aufs problem
  - built from 3146.7-os-image (fe65269b2a438ce8176639e14e6e1f3a09e16b8b)

* `BzKAbSfWFuIlnIRxEpSkdiHDm53nVwlV`
  - bump for stigs (V-38658)

* `R8M_FtmpgpXpOSGvW_ZHBP0uXGCG1wup`
  - periodic bump

* `OS3dVBJ2.EbaTLC.nRT5LSRScnISW80V`
  - update ubuntu for usn-2871-2

* `6O0I3q10J8CyrSUKgAnFh02dRZFg2HTG`
  - update ubuntu packages for USN-2869-1: OpenSSH vulnerabilities

* `yVt32oA.CXzu2YCXBH7zdttGFdSozka1`
  - update ubuntu packages for USN-2865-1, USN-2861-1

* `fAPEi05GreKek9FEiIGYZKfYPhpPCZ3B`
  - update for USN-2861-1

* `YeywOPDDPX0mn3WgSqpxl1gBXcQhtvWv`
  - bump kernel to 3.19.0-43

* `TTmPhUs6RDJUlQmZ.RYMu0ItfOS6FNtx`
  - update monit from 5.2.4 to 5.2.5

* `3mZuzYe8vUwy3L1YhZihMvJ3OEzpDkj.`
  - update for USN-2854-1

* `b6sz6DaogiiWej6NmGsTM1_TwiDaHjBJ`
  - bump ixgbevf to 3.1.1

* `bfSrIiZ6T8z78QW0rDnQbbfYLxIV2FhS`
  - update for USN-2842-1: Linux kernel vulnerabilities

* `Rp2Py4vqFMAfGkz6mMoT5fu2F9SclVBu`
  - update for USN-2836-1: GRUB vulnerability

* `3Zf3rN5HdZX0nNupFQ8Z1VA2J7ueXzGR`
  - update for USN-2834-1: libxml2 vulnerabilities

* `L6G9dXmF3gVQ2xH5_jTAcENCRGkHbqXB`
  - update for USN-2829-1: OpenSSL vulnerability

* `SxNhu4XpwGJ5O3e6qHMZH4OjIKfAmQxc`
  - changes for stigs (V-38466, V-38465, V-38469, V-38472)

* `Z2HxTjdbITWyRL7GCsY1rVe2OjR0oNRZ`
  - update for USN-2821-1: GnuTLS vulnerability

* `EZerQHXisZiL8zX0zpvivfmC.l6UDST7`
  - update for USN-2820-1: dpkg vulnerability

* `dVVR..kD6eL0RtkFO7d1yBOM6hcZCwkO`
  - update for USN-2815-1: libpng vulnerabilities

* `Y1FdmV9WS39Fx9iJaK7oEuqYFXJgp.cK`
  - update for stigs (V-38548, V-38532, V-38600, V-38601)

* `uVOqUoQtxwXO2.7DVCkRyv_RNSayziQM`
  - update libxml2 for usn-2812-1

* `Nh0G1YGSO8pgwCbOHtvDDTk.Ds.7Yxc_`
  - update for USN-2810-1: Kerberos vulnerabilities

* `MwjwmqQgu7CqpIMECnojJ6VZLiwQhDQz`
  - changes for stigs (V-38523, V-38524, V-38526, V-38529)

* `kNxr8G52rcPMvg5tafh7ldLyAjR3X6g6`
  - changes for blank passwords

* `xMl7HhuREluPZP0YyHZLnxhlHZXrB723`
  - update linux image for USN-2806-1

* `Zibxbt9mNrQnPmgwVXjtVnFJZYiJZT6m`
  - update linux image for USN-2798: kernel (Vivid HWE) vulnerabilities

* `N81hCvgAbYz5JLVlJwpEclmeTegW66qd`
  - update unzip for USN-2788-1: unzip vulnerabilities

* `.4y0e8CHJ4a3mZ3VPpKPAFW3OKxnRmrv`
  - add bosh_sudoers group

* `8LbjKPGE07yEeDNp7RkIRe6xdDI3Jre.`
  - yanked

* `7DQf.gOqy.oQcPBa19sgcbOHcvi458La`
  - yanked

* `L8DtBIngBPbziIOl9UZoyAocxGiUfpdL`
  - yanked

* `Ry5gW034s1xK65YcBEdmuL.ermC3iiE7`
  - yanked

* `t4kWs38oNti4vRrKE9xicElzLb4wCTBm`
  - update kernel for USN-2778-1

* `HU9BVWuGxWwoxJ2jOJYKqDRTjwh419Ig`
  - update kernel for USN-2765-1

* `k74zFOTewcP.k8apaBVH5jS5t87c.IaJ`
  - update rpcbind to 0.2.1-2ubuntu2.2 for USN-2756-1

* `7xLESQCJHkDBRAUr5A6zush.6fZwQ1Dp`
  - update kernel for USN-2751-1

* `Z2u8KpEbHMXu1sYd1lI1VC_RPZGGSYoz`
  - add package for growpart command

* `07SVLfhlpQJWWKphcELs9MV2pwgs1n3y`
  - update ubuntu for FreeType vulnerabilities for USN-2739-1

* `Ty4YAJAYPLWkhtcuJdBytQungO6WXdvu`
  - update kernel for USN-2738-1

* `VUlbpM_lQcwk2XCzQ6.bv1DDLNdQf_mZ`
  - update libexpat and lib64expat for USN-2726-1

* `Y5msN.ChBUBRNvr16rYmtHwjEgKCBaZI`
  - changes for stig

* `1B_yfR3ukFZiCHqopmybOTo13Afq_Nci`
  - update kernel and openssh-server for USN-2718-1 & USN-2710-2

* `EYBafGzUZcQNZ.kwk825bNc.4RUmGGaV`
  - update openssh-server for USN-2710-1

* `UNdcxBFcKRVwhrWu2YQZeJkyiPTItQni`
  - disable single-user mode boot in grub2
  - disable bluetooth module and service

* `RVb_.SznfEzXu3kZuE6BNKSOUtYXlDTR`
  - bump libsqlite3-0 to 3.8.2-1ubuntu2.1

* `pAGNPBUCevAW_h90_tfvW8n3gcsU.Fwr`
  - bump libpcre3 to 1:8.31-2ubuntu2.1

* `kJJV2BteRngZzymVqhbV7rwnsDCfUqRL`
  - update kernel to 3.19.0-25-generic

* `ilfxvb._1aLvgmilbcTGnWoeeL1fq54g`
  - update kernel to 3.19.0-23-generic

* `1YmBmEqA4WqeAv7ImLTh3L3Uka4g0kY9`
  - ssh changes for stig

* `sCkRwPmfK0FfRg8zBGlFNnxmG7rs66KO`
  - update configuration for sshd according to stig

* `SRZf0PiUGIC_AeYmJaxhpS5CbJHsZ5ED`
  - update the ixgbevf driver to 2.16.1

* `Hd33DvSkQIgfJhXz0nNeaYxALZe2O0FO`
  - update kernel to 3.19.0-22-generic

* `D98JkW2IWZ2npUMxo6dzidyf0IL45aUU`
  - update kernel to linux-generic-lts-vivid

* `Ua2BPwAV4jhl0egqdsCGujInYlIpFfGe`
  - update unattended-upgrades to 0.82.1ubuntu2.3

* `DRT11QyZUb3Y.tbS00W3QgAQ_lWMhVYJ`
  - update python to version python3.4 amd64 3.4.0-2ubuntu1.1

* `xLfl7rZVgkXKijjY11rSOGk.AJ8KcmEV`
  - update kernel to 3.16.0-41-generic 3.16.0-41.57~14.04.1

* `mVdBreXVEW3jTtuPMUWm0NaQ2tmEuBkp`
  - update kernel to 3.16.0-41-generic

* `mevqBoryhMFMxQa6.O_7WMsHOjxj8Ypi`
  - update libssl to 1.0.1f-1ubuntu2.15

* `CXy2D8rlo7.asw2H7mzCuUmkzVr30vkc`
  - update kernel to 3.16.0-39-generic

* `DjCfP9Rgj37M0R3ccOOm9._SyF5RipuC`
  - update kernel and packages

* `gXS8tB8AlsACLxca1aOF.A2dJroEW9Wx`
  - update kernel

* `4wantbBiSSKve58dnjaR2wSemOAM7Xiy`
  - upgrade rsyslog to version 8.x (latest version in the upstream project's repo)

* `hdWMpoRhNlIYrwt61zt9Ix2mYln_hTys`
  - remove unnecessary packages to make OS image smaller
  - reduce daily and weekly cron load
  - randomize remaining cronjob start times to reduce congestion in clustered deployments

* `0YARMwfbXRhCyma2hdTZTd97IlZqW3Qc`
  - Add hmac-sha1 to sshd_config (required by go ssh lib)

* `G.Wzs2o9_mu6qvC2Nq7ZUvvo6jJSHjC8`
  - update libgnutls26 to 2.12.23-12ubuntu2.2

* `Hcp6Wc4bQp9WB0i.y_2Z4qYzsO.7AXht`
  - update libssl to 1.0.1f-1ubuntu2.11

* `jU0u9AnG550hgtZhH4TS30eU0lOJZxWn`
  - update libc6 to 2.19-0ubuntu6.6
  - update linux-headers to 3.16.0-31

* `bUE_h7edxT9PNKT6ntBKvXH8MzK3.wiA`
  - update trusty to 14.04.2

* `O6Co_wDMuso7prheiIRVc_Q7_T1sC0EP`
  - upgrade unzip to 6.0-9ubuntu1.3

* `yacqn9ooY2Idc6Fb65QE25zl2MSvPX52`
  - lock down sshd_config permissions
  - disable weak ssh ciphers
  - disable weak ssh MACs
  - remove postfix

* `TjC3SnsvaIhROEa1J1L77Mj21TRikCW0`
  - upgrade unzip to 6.0-9ubuntu1.2

* `xIk.jCEzC5CrI.VrogNsyKRnHBtNIJ1w`
  - Adds kernel flags to enable console output in openstack environments
  - upgrade linux kernel to 3.13.0-45

* `LNYTMCODzn39poV8I4yUg1RxmAfTZPth`
  - upgrade libssl to 1.0.1f-1ubuntu2.8

* `Wxp0XbijOQyo_pYgs3ctYQ0Dc6uPaO.I`
  - switch logrotate to rotate based on size

* `QB8K.uFpJXHYJ4Nm.Of.CALZ_8Vh7sF2`
  - start monit during agent bootstrap

* `shN71hxWcKt1xy54u8H6vcTJX3whZZ1y`
  - disable reverse DNS resolution for sshd

* `VSHa.AirKTKl2thd3d.Ld0LZirE7kK8Z`
  - enable rsyslog kernel logging

* `9_XaaM0qR6ReYHJvyJstqf52IL_1zJOQ`
  - upgrade linux kernel to 3.13.0-39

* `omOTKc0mI6GFkX_HWgPAxfZicfQEvq2B`
  - upgrade bash to 4.3-7ubuntu1.5
  - upgrade libssl to 1.0.1f-1ubuntu2.7

* `qLay8YgGATMjiQZwWv0C26GZ7IUWy.qh`
  - upgrade bash to 4.3-7ubuntu1.4

* `_pB.QMUs1y8oQAvDyjvGI9ccfIOtU0Do`
  - upgrade bash to 4.3-7ubuntu1.3

* `GW4JUpDT_wsDu9TgsDRgXfcNBMVSfziW`
  - upgrade bash to 4.3-7ubuntu1.2

* `9ysc4UIkmhpIhonEJzEeNbIpc8t38KxH`
  - upgrade bash to 4.3-7ubuntu1.1

* `7956UhwNIGtYVKliAcpJFCO7iquWbhQR`
  - install parted

* `cJItjk12ZCUgOo591c10FLHpAcVIwWDZ`
  - update libgcrypt11 to 1.5.3-2ubuntu4.1
  - update gnupg to 1.4.16-1ubuntu2.1

* `P9CaP1LYyF6DBXYWEf0G7mf2qY2z_l1D`
  - update kernel to 3.13.0-35.62 and libc6 to 2.19-0ubuntu6.3

* `pGDuX7KzvJI7sXfGDU5obN8qxcD03e57`
  - update kernel to 3.13.0-34.60

* `EhzrTcjEIEfEBBfcl3dnlBld2ZDjTveA`
  - using latest libssl `1.0.1f-1ubuntu2`

* `KXC8x5eWAI71IOc_IelrkLEGNA6_cjRw`
  - Remove resolv.conf clearing from firstboot.sh
  (3c785776c5093995e66bb1dce3253dfbeec51e40)

* `b8ix9.SJvvOTxDP5kV6cWNdkWpSxY6tn`
  - update kernel to 3.13.0-32.56
  (d2be16d309d891cf4e2fe6ab3c21f4bb8f800c22)

* `kpMtaz33W38LnRuUL_ArWoNKIJwaS6Jb`
  - using latest OpenSSL `1.0.1f`
  (23fe6fcd8518446cbdbec360c2f1e4b37834db88)

* `4oXc4U0orsQS944oCY_am5FqAqHXMhFK`
  - update kernel to 3.13.0.29, updated syslog configuration
  (6927f02e9d3c02e6a7dfdece3d4802704572df2c)

* `ETW9GFwQPNRAknS1SSanJaVA__aL5PfN`
  - swapaccount set, ca certifactes installed
  (f87f2cbd89da47f56e23d15ed232a41178587227)

* `FlU8d.nSgbEqmcr0ahmoTKNbk.lY95uq`
  - Ubuntu 14.04
  (e448b0e8b0967288488c929fbbf953b22a046d1d)


## CentOS 6.6

CentOS 6.6 images have filename `bosh-centos-6-os-image.tgz`

* `p8M5lmQFEzXDA3MKeiDMsdLq6jVkJOQt`
  - changes for stig

* `gVPTz59wj9kHj1nBzzymxbhm1yvPe.Q.`
  - remove mesg from profile

* `u1vhDkA5HGFmGJfb9Qg4tBQkE_AMlTOh`
  - load bashrc in non-login shell

* `Q43Dju2RvjPkbWakc33SAGCwrXAPGZiV`
  - update kernel and packages

* `2wi4CWKxfqSLjKQp0T4IKcAPaNFNhCFG`
  - update kernel

* `kkUYP.4sM_hdsn3Sfcr6ksahFpPgb2D8`
  - Add hmac-sha1 to sshd_config (required by go ssh lib)

* `3Yu.JSS0rB0oV6Gt3QnFfxaxvRju71bQ`
  - lock down sshd_config permissions
  - disable weak ssh ciphers
  - disable weak ssh MACs

* `lUG9hrPUDugWx4Sv5vuKiN1X2Z1.lN.8`
  - Adds kernel flags to enable console output in openstack environments

* `.EqtRtHJyHTr3hg4nFPq5QmJ4UxQ2WU.`
  - upgrade linux kernel to 3.13.0-45

* `ISA4tKjaoq4koVay5rAzNZlzX7X0KafH`
  - patch GNU libc to resolve CVE-2015-0235, "GHOST"

* `aoUtngdallpd2f6HhMxCveFvk6t6B2Ru`
  - upgrade openssl to 1.0.1e-30.el6_6.5

* `Hb884_xVvhoIhdTEmMtaTHKC.s7b9AmN`
  - switch logrotate to rotate based on size

* `xbBfE2GA7AgmCGA6MfNfhHX67vkJlIze`
  - start monit during agent bootstrap

* `PB2C5YnPG.zZ5MgjBR96Y40UDpqVQb_D`
  - disable reverse DNS resolution for sshd

* `6mBEQ5Gt5O6NJIFZxlyrf_05i.6s0OWF`
  - CentOS 6.6


## CentOS 7

CentOS 7 images have filename `bosh-centos-7-os-image.tgz`

* `FhRtQM0IZRIcd7MUw3SLluqosKckFFXD`
  - USN-3087-2: OpenSSL regression
  - build from 257.x-3263.x (f95f6355f4072501b2adcad72603ed558380b5d0)

* `rf5dgfOjrHVARcLz8.WchFatRffL7U1g`
  - USN-3087-1: OpenSSL vulnerabilities
  - build from 257.x-3263.x (4a25cba4e8a376337a877cba5ab773fe4512da8a)

* `75nXPiK.._zyEyusgiwlQBVlVUc2uq_L`
  - USN-3084-*: kernel vulnerabilities
  - built from 257.x-3263.x (793365982c27b4f6a49aa90b95f514f1ffe56677)

* `3MOAZkHJszaepuCsTUpqtIuOFNAYkpWg`
  - Backport azure ephemeral disk on root (4548e8e)
  - Backport google file perms fix (d5b1ac9)
  - Backport disable ssh host key gen (444bb0e)
  - Backport hostname length fix (74893f2)
  - Backport udf kernel change (38d42b7)
  - Backport tcp keepalive (079d956)
  - Add logic to check if rsyslogd pid file exists before attempting to kill the process by pid (506c939)
  - kill HUP rsyslog upon logrotation (4395509)
  - build from 257.x (2dcd4799eaf8ee8daf44a5d3dfeed8b58cdf9fe9)

* `KvA3dqrWMunJgR.tfjk_MinflPVIdnjU`
  - backport IPv6, /var/log, and /tmp mount fixes
  - built from 257.x (8f958578de96af4234a0b4262c77d0778cdecd3a)

* `rwv9Gt_k8k94lpIbZpvDIpfuHNAK1.x8`
  - USN-3065-1: Libgcrypt vulnerability
  - built from 257.x (623309e8f61b317ad0b01b32a14c9516910b0851)

* `EMmtKu8QybBV_V15316Qn9kcRUfVtJB1`
  - periodic bump
  - built from 257.x (a6ba6c7cb071aee92374a61f0aeef4be46482390)

* `feT5j7pbSjOLz6DmTq2.yvnoDiutWbt7`
  - periodic bump
  - built from develop (383e11d66bb5326eaa342ca695e1b416b50b5c56)

* `yhFKKsGF1r62vIA4UpTjc1qcRCT1fJVp`
  - update for CIS tests
  - built from develop (99aebc025dc4093981395d75be52369ced2d7131)

* `cQdYcoXI4hjmFlxBRyRvC2ROUcdJJEnl`
  - update for CIS tests
  - built from develop (a8d26078eb4a2fb277068381c76da638f40b5b36)

* `NIy8pyhN76gikcaqacX40uxB.ePoKNKJ`
  - update nginx to 1.11.1
  - built from develop (1af67b94cad42ff2133e383afd6d174721253dbc)

* `WTOHgTn21GfhCJIvxY8BLEk0BXJEG7rO`
  - update for CIS tests
  - built from develop (3dfd04cd65c73a01e2f2f1b7310a33687ab27111)

* `UGbyeTxZ1vpbhzmbSmCovLpOLRDCPd4W`
  - periodic bump with rsyslog reload changes
  - built from develop (15a4ef77db335b186d183323f5a1f6819c35bdce)

* `pYgqTvtvYYhvVwsK1YChI_Y.p3ob5XW1`
  - periodic bump
  - built from develop (95f5d9cc816f934db64a80188cf0c9e80ab15dda)

* `sNzzvPR7ZvX8gBdSKLIgLxaR4KNGLoWM`
  - includes gov1 STIGs
  - built from develop (4bc83146a59ddca85d4a56868e520f938dc84843)

* `eppMU7odtc6EZpvt9ZTSxtGnBAQIhKTH`
  - periodic bump to fix auditd STIG
  - built from develop (a6d4a075ad2c58a629fbc9225d75d67cb4c1cd8a)

* `.zprWlSz4bwjb0Te0boPm1yCSegMsoWw`
  - periodic bump to include STIGs
  - built from develop (51750c70da03484321c7c72346742de257bf2fa5)

* `PmZTYI7LCLzSwbhTgfVf7eaBsMVccM8G`
  - periodic bump to include STIGs
  - built from develop (da0fda1f8bb8ee4c63e64a549bfe3727a6ac5b69)

* `EOEnizgLvRMNOR26NDC9bPKvz5UYO6s9`
  - periodic bump to include STIGs
  - built from develop (c6c341baee219b90935430ef120f52fce668f496)

* `CjpfolQ0s2ngCK4wJYgLFv3v6uT4Oc0.`
  - periodic bump to include STIGs
  - built from develop (597cbcd96e631678f7d66c31e39a2ac7ddc6c89d)

* `UCkAP0ZnLPtOIBjuhhz5TdKSM9wb3BPn`
  - periodic bump
  - built from develop (7437419b800cdaf2a163fc5606ec360032f37a28)

* `7qjE9jFXWpH3cUogr7dappkJwThYQpT4`
  - periodic bump

* `ls0CaYm3laag.H5Qdq1QWxIhNHADvkUD`
  - periodic bump

* `cEGmwbyceIup.BGXWOWwN2TPYoJoTsNr`
  - bump for stigs (V-38658)

* `2ZQ9BfHaUhPIATFSOB..99JTymbF1oEY`
  - periodic bump

* `Pg8Zbi7OZvttUGrseCCrYIHVD6WKwbMW`
  - (periodic) bump centos to match ubuntu update

* `TQJviTjjjfBUBtaVr5phBSyfCC_arPrR`
  - (periodic) bump centos to match ubuntu update for USN-2869-1

* `vbWPUGbViswiED.1m6cKU0GdxEu2hL.L`
  - (periodic) bump centos to match ubuntu update for USN-2865-1, USN-2861-1

* `7PHeBQT.8HLySemI1A3c6HY4NBoG1Asc`
  - (periodic) bump centos to match ubuntu update for USN-2861-1

* `qmKgGt1iOX84M.hR8ZVI0887DEvnKPHV`
  - update monit from 5.2.4 to 5.2.5

* `VdAETz96I1jsDYh.Qf8_UgrYTexAmX7U`
  - (periodic) bump centos to match ubuntu update for USN-2854-1

* `x38wS0r6aXVsgfdRvtT.7BM7FBXjsBq.`
  - bump ixgbevf to 3.1.1 and centos release to 7.2

* `VbEGV.FOd56pqHc.Gzw1z.26VkZUPLvA`
  - (periodic) bump centos to match ubuntu update for USN-2829-1

* `llyRse5kYAebEAI4K9uaMJCzRBtr2wHY`
  - changes for stigs (V-38466, V-38465, V-38469, V-38472)

* `7.WUv.iIq4SW.ra1_zusQRTntKCI011_`
  - (periodic) bump centos to match ubuntu update for USN-2821-1

* `yd6fohx_wzcBob_M.h7z66fpzk8tA3O9`
  - (periodic) bump centos to match ubuntu update for USN-2820-1

* `ib7we0khyue8vOIf7hP1fsyMDJwKGki0`
  - (periodic) bump centos to match ubuntu update

* `BkQfdMjmhZWsNqdpDGEVMM0QWkWfPL3M`
  - update for stigs (V-38548, V-38532, V-38600, V-38601)

* `70iKyO1XVyO23ci2JpztKdHMClFu6eVF`
  - (periodic) bump centos to match ubuntu update

* `KJOs81.dHgRSBJ9CgcjOEgxd9I2gO7zF`[USN-2820-1] dpkg vulnerability
  - (periodic) bump centos to match ubuntu update

* `k.v0bPRcoftbZK2nREGM5J4kKmEIZXE5`
  - changes for stigs (V-38523, V-38524, V-38526, V-38529)

* `ibO7C43zyqH5QDmZ1Ozl52FH9dAaYiCP`
  - (periodic) bump centos to match ubuntu update

* `iErRGYf6hJANmRBq0BFiR1PITqufCXLV`
  - (periodic) bump centos to match ubuntu update

* `V8QX.fIS.DODjNJZBaUB1WNSCwKPFyKS`
  - (periodic) bump centos to match ubuntu update

* `2QbANNOEHcpvZeegGUwTOTRRkZ08vHmS`
  - add bosh_sudoers group

* `X7Rvv6Mnv3SsHTXXhjqJlK7PimaKgCfy`
  - yanked

* `gFr4O0SWv4cQZe8ivJ7W8pb8dC_cahOi`
  - yanked

* `1G6GOeAS0ktBhdHhcZhd3rsH3bh7yRh0`
  - yanked

* `TZTJLOEg4z4wGJXSqaHY3fEdu8yWtK.o`
  - yanked

* `60DupjHdE2ef85pZN86s7UfHhNQp1plk`
  - (periodic) bump centos to match ubuntu update

* `3YJSMiU5nD07NEAN8wFJ6uya5XH7WriY`
  - update centos to match ubuntu update for USN-2739-1

* `43zhprNWRQoYBhDBVkJm6uAocH0IBgLw`
  - add package for growpart command

* `upXZonWLgbjXkN1VKg5W560cFsQ.D3J9`
  - symlink /var/run to /run

* `7usDt2skfd6jEm_0EK7NXRMmSG0BYz7r`
  - bump kernel

* `UNpmsea6Zi8Vf93FoqL_Jlxz13v0gozh`
  - update centos to match ubuntu update for USN-2739-1

* `j2ML2KnCoVtBwWUfLYRakaH8vkEQ.eX_`
  - update openssh-server for USN-2710-1

* `4xnMlmLRXupZrn59kVEtCCtb2Zfxia54`
  - disable single-user mode boot in grub2
  - disable bluetooth module and service

* `IL5wqv5zstAX9up9pidNw1c.FMx6JDcN`
  - potential update to kernel, matching Ubuntu change

* `Mbx1XFPOplo4CaqyMQoaorvWt86KSip0`
  - ssh changes for stig

* `Pdz2NlUeMFNPkDqWQnVX5TQ_HVtmaMG5`
  - update configuration for sshd according to stig

* `TX0adnfBytYUQSqhSqI78z_651ENw4sa`
  - update the ixgbevf driver to 2.16.1

* `EQpmK1zMJ3_q.PXd.jTxxEKMw1gJ8kGV`
  - Install open-vm-tools

* `00kmcew_QGZDuzgF49Z.kAPhCA7EFIfQ`
  - update packages

* `1hBkiByEM5v3YhznWLQmmTdhA8eKkb3g`
  - upgrade rsyslog to version 8.x (latest version in the upstream project's repo)

* `uVRZSKujJb4zU2KrtAH.xVLly3agHc7M`
  - reinstall `base` metapackage to enable proper BOSH Director operation

* `0_zs2Y2A.QhW00r1tbb7Oa7XcMY3GdkW`
  - install net-tools for stemcell acceptance testing

* `cNakw6wcTjEyWaZBQWTUuoeYKiuLYB3k`
  - remove unnecessary packages to make OS image smaller
  - reduce daily and weekly cron load
  - randomize remaining cronjob start times to reduce congestion in clustered deployments

* `x0Y6dVzdBHSAt33zNO.aOu_QvY2pqVlT`
  - Auto-restart runsvdir

* `3I9TaTJV5vUkUpGJETzqD8wsWhP2vsFE`
  - CentOS 7
