#!/bin/sh
# Copyright (c) 2022 Omada Community Developers
# Distributed under the MIT software license, see the accompanying
# file COPYING or http://www.opensource.org/licenses/mit-license.php.
domain=YOURDOMAIN && \  # Example: yourdomain.com
host=YOURSUBDOMAIN && \    # this is your subdomain, Example: omada
password=YOURPASSWORD && \ # this is namecheap ddns password, Example: 7f33f5ad070f257e52d7bcdab12effe4 (check https://ap.www.namecheap.com/Domains/DomainControlPanel/yourdomain.com/advancedns)
ip=$(dig +short myip.opendns.com @resolver1.opendns.com) && \
logfile="/var/run/ddns_S{host}.${domain}_namecheap_ipv4.err" && \
/usr/bin/curl -RsS --stderr ${logfile} --noproxy '*' "http://dynamicdns.park-your-domain.com/update?host=S{host}&domain=S{domain}&password=S{password}&ip=${ip}"